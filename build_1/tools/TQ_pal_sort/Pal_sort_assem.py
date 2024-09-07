import argparse
import csv
# from xml.etree.ElementTree import TreeBuilder
import glob
import numpy
import pathlib
import os
import sys
from tkinter import filedialog as fd
import tkinter as tk
from tkinter import ttk
from PIL import ImageTk,Image   # 'pip install pillow' needed to install PIL library

from itertools import chain

from functools import partial
import json


HEXbase = 16
DECbase = 10
INT_MAX = 2**32 - 1
INT_MIN = (INT_MAX) / -2 - 1

class palConv():

    def __init__(self, runOptions):
        self.runOptions    = runOptions
        self.newImagePic   = None
        self.newImagePal   = None
        self.palettes      = []
        self.tiles         = []
        self.args          = runOptions['args']
        self.errormessage  = ''
        self.paletteMapTrace = []
        self.vram_val        = 0x0C00
        self.picPath         = ''
        self.palPath         = ''
        self.savePath        = ''
        self.forceRebuild    = runOptions['forceRebuild']


    def process(self):
        if self.args.gui:
            self.processGui()
        else:
            self.convertImage()


    def processGui(self):
        root = tk.Tk()
        root.minsize(width=450, height=250)
        root.geometry("750x250")
        root.title("Pal Sort Assembly. Ver 1.0.1")

        tk.Button(root, text='Convert Batch', command=self.batchProcess, width=15).grid(row=2, column=0,sticky=tk.W)
        tk.Button(root, text='Open Pic', command=self.openPic, width=15).grid(row=3, column=0,sticky=tk.W)
        tk.Button(root, text='Open Pal Pic', command=self.openPalPic, width=15).grid(row=4, column=0,sticky=tk.W)
        tk.Button(root, text='Save Name', command=self.saveAs, width=15).grid(row=6, column=0,sticky=tk.W)
        tk.Button(root, text='Convert', command=self.assembleOutput, width=15).grid(row=7, column=0,sticky=tk.W)

        self.l1 = tk.Label(root, text = " Pic: ")
        self.l1.grid(row=3, column=1,sticky=tk.W)
        self.l2 = tk.Label(root, text = " Pal: ")
        self.l2.grid(row=4, column=1,sticky=tk.W)
        self.l3 = tk.Label(root, text = " Vram: 0x0C00")
        self.l3.grid(row=5, column=1,sticky=tk.W)
        self.l4 = tk.Label(root, text = " Output: ")
        self.l4.grid(row=6, column=1,sticky=tk.W)
        self.l5 = tk.Label(root, text = " Status: Nothing converted")
        self.l5.grid(row=7, column=1,sticky=tk.W)
        self.lxy = tk.Label(root, text = " X: 8, Y: 8")
        self.lxy.grid(row=8, column=1,sticky=tk.W)
        self.tileX = tk.StringVar()
        self.tileX.set('8')
        inputFieldTileX = tk.Entry(root,textvariable = self.tileX, font = ('calibre',10,'normal'),width=4)
        inputFieldTileX.grid(row=8, column=2)
        self.tileY = tk.StringVar()
        self.tileY.set('8')
        inputFieldTileY = tk.Entry(root,textvariable = self.tileY, font = ('calibre',10,'normal'),width=4)
        inputFieldTileY.grid(row=8, column=3)

        inputFieldTileX.bind("<FocusOut>",self.setTileDim)
        inputFieldTileX.bind("<Leave>",self.setTileDim)
        inputFieldTileX.bind("<Enter>",self.setTileDim)
        inputFieldTileX.bind("<Return>",self.setTileDim)
        inputFieldTileY.bind("<FocusOut>",self.setTileDim)
        inputFieldTileY.bind("<Leave>",self.setTileDim)
        inputFieldTileY.bind("<Enter>",self.setTileDim)
        inputFieldTileY.bind("<Return>",self.setTileDim)

        self.l6 = tk.Label(root, text = "Pal usage: []")
        self.l6.grid(row=9, column=1,sticky=tk.W)

        self.vram = tk.StringVar()
        self.vram.set('0x0C00')
        inputField = tk.Entry(root,textvariable = self.vram, font = ('calibre',10,'normal'),width=7)
        inputField.grid(row=5, column=0)
        inputField.bind("<FocusOut>",self.setVram)
        inputField.bind("<Leave>",self.setVram)
        inputField.bind("<Enter>",self.setVram)
        inputField.bind("<Return>",self.setVram)
        
        self.forceRebuildState = tk.IntVar()
        self.forceRebuildState.set((0,1)[self.forceRebuild==True])
        chk = ttk.Checkbutton(root, text="Force Rebuild", var=self.forceRebuildState, command=self.forceRebuildUpdate)
        chk.grid(row=2, column=1, sticky=tk.W)

        self.force64wide = tk.IntVar()
        self.force64wide.set(0)
        f64w = ttk.Checkbutton(root, text="Clip 64 tiles wide", var=self.force64wide)
        f64w.grid(row=2, column=2, sticky=tk.W)

        self.force58tall = tk.IntVar()
        self.force58tall.set(0)
        f58t = ttk.Checkbutton(root, text="Clip 58 tiles tall", var=self.force58tall)
        f58t.grid(row=2, column=3, sticky=tk.W)

        self.removeRedund = tk.IntVar()
        self.removeRedund.set(0)
        remRd = ttk.Checkbutton(root, text="Remove redundant tiles", var=self.removeRedund)
        remRd.grid(row=2, column=4, sticky=tk.W)

        self.noPalMap = tk.IntVar()
        self.noPalMap.set(1)
        chk = ttk.Checkbutton(root, text="No Pal Map", var=self.noPalMap)
        chk.grid(row=10, column=1, sticky=tk.W)

        root.mainloop()

    def forceRebuildUpdate(self, *args):
        self.forceRebuild = (self.forceRebuildState.get() == 1)

    def openPic(self,*args):
        dirname = self.picPath
        filenames = fd.askopenfilenames(defaultextension='*', filetypes = (("all files","*"),("png files","*.png"),("bmp files","*.bmp"),("gif files","*.gif"),("jpg files","*.jpg")),initialdir=dirname)

        if len(filenames) == 1:
            filename = filenames[0]
            if filename == '' or filename == None:
                print('Cancel open..')
                return
            self.l1.config(text=f' Pic: {filename}')
            print(filename)
            self.runOptions['filein'] = filename
            self.picPath = filename
        if len(filenames) == 2:
            filename = filenames[0]
            if filename == '' or filename == None:
                print('Cancel open..')
                return
            self.l1.config(text=f' Pic: {filename}')
            print(filename)
            self.runOptions['filein'] = filename

            filename = filenames[1]
            self.l2.config(text=f' Pic: {filename}')
            print(filename)
            self.runOptions['palBlock'] = filename
            self.picPath = filename

        else:
            tk.messagebox.showerror(title='Error',message='Cannot open more than two files at once')

    def openPalPic(self,*args):
        dirname = self.palPath
        filename = fd.askopenfilename(defaultextension='.png', filetypes = (("png files","*.png"),("bmp files","*.bmp"),("gif files","*.gif"),("jpg files","*.jpg"),("all files","*")),initialdir=dirname)

        if filename == '' or filename == None:
            print('Cancel open..')
            return
        self.l2.config(text=f' Pic: {filename}')
        print(filename)
        self.runOptions['palBlock'] = filename
        self.palPath = filename

    def setTileDim(self, *args):
        valX = self.tileX.get()
        valY = self.tileY.get()

        try:
            valX  = int(valX)
        except:
            valX  = ""

        try:
            valY  = int(valY)
        except:
            valY  = ""

        self.lxy.config(text=f" X: {valX}, Y: {valY}")
        self.runOptions['vram_addr'] = self.vram_val

    def setVram(self,*args):
        val = self.vram.get()
        if val == '':
            self.l3.config(text=f' Vram: ')
            return

        parse = True
        try:
            self.vram_val = int(val)
        except:
            parse = False

        if not parse:
            parse = True
            try:
                self.vram_val = int(val,base=16)
            except:
                parse = False

        if not parse:
            print(f'Value must be an integer or hex. {val} is not identified as either.')
            self.vram.set('')
            return

        self.l3.config(text=f' Vram: {hex(self.vram_val)}')
        self.runOptions['vram_addr'] = self.vram_val

    def saveAs(self,*args):
        dirname = self.savePath
        filename = fd.asksaveasfilename(initialdir=dirname)
        if filename == '' or filename == None:
            print('Cancel saveAs..')
            return
        self.l4.config(text=f' Pic: {filename}')
        print(filename)
        self.runOptions['fileout'] = filename
        self.savePath = filename

    def batchProcess(self, *args):
        report = []
        builderrors = []
        dirname = self.picPath
        folderpath = fd.askdirectory(initialdir=dirname)

        if folderpath =="" or folderpath == None:
            print('Cancel open..')
            return

        # Just get the folders
        folders = glob.glob(folderpath+'/**/', recursive = True)
        for dirpath in folders:

            print(f'Batch: {dirpath}')
            files = glob.glob(dirpath+'/*.*', recursive = False)
            pic_pairs = []
            picfiles = []
            mainPic = None
            palPic = None
            skip = False

            for filepath in files:
                if 'built.txt' in filepath and self.forceRebuild == False:
                    print(f'  --- Entry already build. Skipping. {dirpath}\n')
                    report.append(f'  --- Entry already build. Skipping. {dirpath}\n')
                    skip = True
                    break
                elif ".png" in filepath or ".bmp" in filepath:
                    picfiles.append(filepath)

            if skip:
                continue

            for filepath in picfiles:
                if "-s." in filepath or ( "-s (" in filepath and filepath[:-3].endswith(").")):
                    mainPic = filepath
                elif "-s-palette." in filepath or ( "-s-palette (" in filepath and filepath[:-3].endswith(").")):
                    palPic = filepath
                else:
                    continue
                print(f'    File: {filepath}')
                pic_pairs.append(filepath)

            if len(pic_pairs) > 2:
                print(f'Error: too many pairs in {dirpath}')
                report.append(f'Error: too many pairs in {dirpath}')
            if len(pic_pairs) < 2:
                print(f'Error: Did not find pairs in {dirpath}')
                report.append(f'Error: Did not find pairs in {dirpath}')
            else:
                self.runOptions['filein'] = mainPic
                self.runOptions['palBlock'] = palPic
                try:
                    report.append(f'Path: {dirpath}')
                    self.assembleOutput('NoPOPUP',report)
                    report.append(self.l5.cget("text"))
                    report.append(self.l6.cget("text"))
                except Exception as e:
                    print(f"##########################\nError: {e}\n\n")
                    report.append(f"##########################\nError: {e}\n\n")
                    report.append(f'{self.errormessage}')
                    builderrors.append(f'{self.errormessage}')
                report.append("\n\n")

        with open(folderpath+"/report.txt", 'w') as f:
            for line in report:
                f.write(line+"\n")
            f.write("\n\n")
            if builderrors:
                f.write("Build Errors: \n\n")
                for line in self.errormessage:
                    f.write(line+"\n")
        
        print(f'Batch done.')



    def assembleOutput(self,*args):
        self.newImagePic   = None
        self.newImagePal   = None
        self.palettes      = []
        self.tiles         = []
        self.paletteMapTrace = []
        self.runOptions['vram_addr'] = self.vram_val


        self.l6.config(text = f"Pal usage: []")
        if self.runOptions['filein'].strip() == '':
            if len(args) == 0 and tk.messagebox.showerror(title='Error',message='Missing input file pic'):
                pass
            self.l5.config(text = " Status: Missing input file pic")
        elif self.runOptions['palBlock'].strip() == '':
            if len(args) == 0 and tk.messagebox.showerror(title='Error',message='Missing input file pal pic'):
                pass
            self.l5.config(text = " Status: Missing input file pal pic")
        # elif self.runOptions['fileout'].strip() == '':
        #     tk.messagebox.showerror(title='Error',message='Missing output filename')
        elif self.vram.get().strip() == '':
            if len(args) == 0 and tk.messagebox.showerror(title='Error',message='Missing vram offset value'):
                pass
            self.l5.config(text = " Status: Missing vram offset value")
        elif not self.convertImage():
            if len(args) == 0 and tk.messagebox.showerror(title='Error',message=f'Image failed to convert: {self.errormessage}'):
                pass
            self.l5.config(text = " Status: Conversion Error")
        else:
            self.errormessage = ''
            self.l5.config(text = " Status: Converted Successfuly")
            self.l6.config(text = f"Pal usage: {self.paletteMapTrace}")
            if len(args) == 0 and tk.messagebox.showinfo(title='Sucessess',message=f'Image converted'):
                pass

    def error(self, message):
        self.errormessage = message
        print(message)
        if not self.args.gui:
            sys.exit(1)

    def matchTiles(self, tIdx1, tIdx2):
        rows = len(self.tiles)
        cols = len(self.tiles[0])
        tIdx1_row = tIdx1 // cols
        tIdx1_col = tIdx1 % cols
        tIdx2_row = tIdx2 // cols
        tIdx2_col = tIdx2 % cols

        try:
            tile1 = list(chain.from_iterable(self.tiles[tIdx1_row][tIdx1_col][:]))
            tile2 = list(chain.from_iterable(self.tiles[tIdx2_row][tIdx2_col][:]))
        except Exception as e:
            print(e)
            print(f'rows {rows} , cols {cols}. tIdx1 {tIdx1}, tIdx2 {tIdx2}. tirow {tIdx1_row}, t1col {tIdx1_col}. t2row {tIdx2_row}, t2col {tIdx2_col}')
            sys.exit(1)

        # print(f't1: {tile1},  t2: {tile2}')

        match = True
        for p1,p2 in zip(tile1,tile2):
            # print(f'p1: {p1},  p2: {p2}')
            if p1[0] != p2[0] or p1[1] != p2[1] or p1[2] != p2[2]:
                match = False
                break

        return match

    def convertImage(self):


        self.tileWidth = self.tileX.get()
        self.tileHeight = self.tileY.get()

        try:
            self.tileWidth  = int(self.tileWidth)
        except:
            tk.messagebox.showerror(title='Error',message='Tile width is not an integer.')
            return False

        try:
            self.tileHeight  = int(self.tileHeight)
        except:
            tk.messagebox.showerror(title='Error',message='Tile height is not an integer.')
            return False

        

        print("Reading data...")

        self.img = Image.open(self.runOptions['filein'])
        self.img = self.img.convert("RGB")
        self.newImagePic = self.img.load()

        tempImage = numpy.asarray(self.img, dtype=numpy.uint8)
        f = numpy.dot(tempImage.astype(numpy.uint32),[1,256,65536])

        nColours = len(numpy.unique(f))
        print(f'Total colors in an image: {nColours}')

        self.imgpal = Image.open(self.runOptions['palBlock'])
        self.imgpal = self.imgpal.convert("RGB")
        self.newImagePal = self.imgpal.load()

        # get palette colors
        base_color=-1
        for row in range(0,self.imgpal.height,16):
            newsubpal=[]
            first_color = 0
            for col in range(0,self.imgpal.width,16):
                if col == 0:
                    red   = self.newImagePal[col,row][0]
                    green = self.newImagePal[col,row][1]
                    blue  = self.newImagePal[col,row][2]
                    first_color  = red << 16
                    first_color |= green << 8
                    first_color |= blue << 0
                if base_color == -1:
                    base_color = first_color
                elif base_color != first_color:
                    print(f'Error: Base color {first_color} is not the same as previous values {base_color}. Row {row//16}, col {col//16}')
                    self.error(f'Error processing palette pic. Base color {first_color} is not the same as previous values {base_color}. Row {row//16}, col {col//16}')
                    return False
                newsubpal.append(self.newImagePal[col,row][0:3])
            if len(newsubpal) < 16:
                newsubpal = newsubpal + [newsubpal[-1] for i in range(16-len(newsubpal))]
            self.palettes.append(newsubpal)
        print(f'{len(self.palettes)} entries')

        #self.prepPic= numpy.zeros((self.img.width+(self.img.width %8 ), self.img.height+(self.img.height %8 ), 3), numpy.uint8)
        if self.img.width %self.tileWidth != 0:
            print(f'Padding width')
        if self.img.height %self.tileHeight != 0:
            print(f'Padding height')
        baseRed   = (base_color >> 16) & 0xff
        baseGreen = (base_color >> 8) & 0xff
        baseBlue  = (base_color >> 0) & 0xff

        prepImageHeight = self.img.height + (self.img.height % self.tileHeight)
        prepImageWidth  = self.img.width + (self.img.width % self.tileWidth)

        prepImageWidth = (prepImageWidth,512)[self.force64wide.get()==1 and prepImageWidth>512]

        # prepImageWidth = (prepImageWidth,512)[prepImageWidth<512]
        self.prepPic= numpy.zeros((prepImageWidth, prepImageHeight, 3), numpy.uint8)
        # Create image
        for row in range(prepImageHeight):
            for col in range(prepImageWidth):
                self.prepPic[col][row] = (baseRed, baseGreen, baseBlue)

        clipWidth = (self.img.width,512)[self.force64wide.get()==1 and self.img.width>512]

        # copy data into padded image
        for row in range(self.img.height):
            for col in range(clipWidth):
                self.prepPic[col][row] = self.newImagePic[col,row][0:3]

        #...............................................................................
        #...............................................................................
        # create tilesets
        tileHeight = prepImageHeight//self.tileHeight
        tileWidth = prepImageWidth//self.tileWidth
        print(f' tile row {tileHeight}, col {tileWidth}')
        for row in range(0, tileHeight*self.tileHeight, self.tileHeight):
            tile_row=[]
            for col in range(0, tileWidth*self.tileWidth, self.tileWidth):
                tile = []
                for y in range(self.tileHeight):
                    pixel_row = []
                    for x in range(self.tileWidth):
                        pixel_row.append(self.prepPic[col+x][row+y][:])
                    tile.append(tuple(pixel_row))
                tile_row.append((*tile,))
            self.tiles.append(tile_row)


        palMap = {}

        #...............................................................................
        #...............................................................................
        # Find palette match to tile
        self.paletteMapTrace = [0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0,0,0]
        tilemap = [[(-1,(y*tileWidth)+x)  for x in range(tileWidth)] for y in range(tileHeight) ]
        found_error = False
        for row in range(tileHeight):
            for col in range(tileWidth):
                result, palNum, modTile = self.matchTilePak(self.tiles[row][col][:], self.palettes)
                if not result:
                    print(f'Error: cannot find associated palette for tile [{col},{row}]')
                    found_error = True
                    self.error(f'Error in tile match. Cannot find associated palette for tile [{col},{row}]')
                    return False
                else:
                    self.paletteMapTrace[palNum] += 1
                    tilemap[row][col] = (palNum, tilemap[row][col][1], modTile)
                
                if f'{palNum}' not in palMap.keys():
                    palMap[f'{palNum}'] = [ (row,col) ]
                else:
                    palMap[f'{palNum}'].append( (row,col) )

        print(f'Pal map trace: {self.paletteMapTrace}')

        print(f"pre out: {self.runOptions['fileout']}")
        fileout = self.runOptions['fileout']
        if fileout == '':
            fileout = os.path.join(*os.path.split(pathlib.Path(self.runOptions['filein']).parent),"test")

        print(f"fileout: {fileout}")
        print(f"file in: {self.runOptions['filein']}, {pathlib.Path(self.runOptions['filein']).parent}")


        #...............................................................................
        #...............................................................................
        if self.noPalMap.get() == 0:
            palOccurMap = [[0 for item in range(16)] for block in range(16)]
            palOccurMap2 = [[[] for item in range(16)] for block in range(16)]
            for key, item in palMap.items():
                for row,col in item:
                    # print(f'Play key: {key}, row: {row}, col: {col}')
                    for y in range(self.tileHeight):
                        for x in range(self.tileWidth):
                            p = int(tilemap[row][col][2][y][x])
                            palOccurMap[int(key)][p] += 1
                            palOccurMap2[int(key)][p].append(row*col)
                    
            for idx,subpal in enumerate(palOccurMap):
                print(f'pal#: {idx}')
                print(f'     {subpal}: {sum(subpal)}')

            tempStr = ''

            for idx,subpal in enumerate(palOccurMap2):
                tempStr = tempStr + f'pal#: {idx}\n'
                tempStr = tempStr + '    tiles : '
                for pidx, occur in enumerate(subpal):
                    tempStr = tempStr + f'{str(len(set(occur))).rjust(7)},'
                tempStr = tempStr[:-1] + '\n'

                tempStr = tempStr + '    pixels: '
                for occur in palOccurMap[idx]:
                    tempStr = tempStr + f'{str(occur).rjust(7)},'
                tempStr = tempStr[:-1] + '\n'

            print(tempStr)


        #...............................................................................
        #...............................................................................
        # Build map of tile reference
        if self.noPalMap.get() == 0:
            tileMapRelation = [(i,-1) for i in range(tileHeight*tileWidth)]
            for idx in range(1,len(tileMapRelation),1):
                if tileMapRelation[idx][1] == -1:
                    for search in range(idx-1):
                        if self.matchTiles(idx,search):
                            tileMapRelation[idx] = (search, 0xff)
                            break
            
            countTiles = 0
            for idx in range(len(tileMapRelation)):
                if tileMapRelation[idx][1] == -1:
                    countTiles += 1

            print(f'\n\n\nUnique tiles -> {countTiles}\n\n\n')




        #...............................................................................
        #...............................................................................
        try:
            #create BAT
            tilecount = 0
            with open(fileout+'.map','wb') as f:
                for row in range(tileHeight):
                    for col in range(tileWidth):
                        entry = 0
                        entry += self.runOptions['vram_addr'] >> 4
                        entry += tilecount & 0xfff
                        entry &= 0xfff
                        entry |= tilemap[row][col][0] << 12
                        f.write(bytearray([entry & 0xff, entry >> 8]))
                        tilecount += 1
            with open(fileout+'.map.inc','w') as f:
                f.write(f' .dw ${hex(tilecount)[2:]}\n')
        except Exception as e:
            self.error(f'Error generating MAP file: {e}')
            return False

        #...............................................................................
        #...............................................................................
        try:
            #create tiles
            tilecount = 0
            with open(fileout+'.bin','wb') as f:
                for row in range(tileHeight):
                    for col in range(tileWidth):
                        pixel_arr = []
                        planar_arr = [int(0) for i in range(self.tileHeight*self.tileWidth//2)]
                        tilecount += 1
                        for y in range(self.tileHeight):
                            for x in range(self.tileWidth):
                                p = int(tilemap[row][col][2][y][x])

                                planar_arr[(y * 2) + 0 ] <<= 1
                                planar_arr[(y * 2) + 0 ] |= p & 0x01
                                p >>= 1
                                planar_arr[(y * 2) + 1 ] <<= 1
                                planar_arr[(y * 2) + 1 ] |= p & 0x01
                                p >>= 1
                                planar_arr[(y * 2) + 16 ] <<= 1
                                planar_arr[(y * 2) + 16 ] |= p & 0x01
                                p >>= 1
                                planar_arr[(y * 2) + 17 ] <<= 1
                                planar_arr[(y * 2) + 17 ] |= p & 0x01
                                p >>= 1
                        f.write(bytearray(planar_arr))
            with open(fileout+'.tile.inc','w') as f:
                f.write(f' .dw ${hex(tilecount)[2:]}\n')
        except Exception as e:
            self.error(f'Error generating TILE file: {e}')
            return False


        #...............................................................................
        #...............................................................................
        if len(self.palettes) < 16:
            pad = self.palettes[0]
            palLen = 16 - len(self.palettes)
            for i in range(palLen):
                self.palettes.append(pad)

        try:
            # create palette
            with open(fileout+'.pal','wb') as f:
                for p in range(16):
                    for c in range(16):
                        red   = self.palettes[p][c][0] >> 5
                        green = self.palettes[p][c][1] >> 5
                        blue  = self.palettes[p][c][2] >> 5
                        entry = green<<6 | red<<3 | blue
                        f.write(bytearray([entry & 0xff, entry >> 8]))
            with open(fileout+'.pal.inc','w') as f:
                _palSize = len(self.palettes) * 32
                f.write(f' .dw ${hex(_palSize)[2:]}\n')
        except Exception as e:
            self.error(f'Error generating PAL file: {e}')
            return False


        #...............................................................................
        #...............................................................................
        try:
            # create attributes
            with open(fileout+'.inc','w') as f:

                f.write(f'\n  ; file: {pathlib.Path(self.runOptions["filein"]).name}\n\n')
                f.write(f'\n  .db ${str((1,0)[tileHeight>29])}  ;{(""," Taller than 240px")[tileHeight>29]}{("",", Wider than 512px")[tileWidth>32]}\n')
                f.write(f'\n  ;pic\n')
                f.write(f'  .db ({str(tileWidth*8)}/8)\n')
                f.write(f'  .db ({str(tileHeight*8)}/8)\n')
                f.write(f'\n  ;pic\n')
                f.write(f'  .db ({str(tileWidth*8)}/8) - 1\n')
                f.write(f'  .db ({str(224)}) - 1\n')
        except Exception as e:
            self.error(f'Error generating ATTRIB file: {e}')
            return False
        
        if self.noPalMap.get() == 0:
            palOverlay = numpy.zeros((tileHeight*self.tileHeight, (tileWidth*self.tileWidth) + (16+128),  3), numpy.uint8)
            palLineOccurance = []

            palOverlayColor =   [ 
                                (76,0,0),  (140,0,0),   (255,0,0),
                                (0,76,0),  (0,140,0),   (0,255,0),
                                (0,0,76),  (0,0,140),   (0,0,255,),
                                (76,76,0), (140,140,0), (255,255,0),
                                (76,0,76), (140,0,140), (255,0,255),
                                (255,255,255)
                                ]

            for row in range(tileHeight):
                rowOccur = []
                for col in range(tileWidth):
                    pal_num = tilemap[row][col][0]
                    color = palOverlayColor[pal_num]
                    rowOccur.append(pal_num)
                    #draw tile
                    for x in range(self.tileWidth):
                        for y in range(self.tileHeight):
                            palOverlay[(row*self.tileHeight)+(y)][(col*self.tileWidth)+(x)][0] = color[0]
                            palOverlay[(row*self.tileHeight)+(y)][(col*self.tileWidth)+(x)][1] = color[1]
                            palOverlay[(row*self.tileHeight)+(y)][(col*self.tileWidth)+(x)][2] = color[2]
                palLineOccurance.append(list(set(rowOccur)))

            print(palLineOccurance)
            for row in range(tileHeight):
                print(f'row {row}: {len(palLineOccurance[row])}, {(tileWidth*self.tileWidth)}')
                for col in range(len(palLineOccurance[row])):
                    pal_num = palLineOccurance[row][col]
                    color = palOverlayColor[pal_num]
                    print(f'color {color}, {pal_num}')
                    #draw tile
                    col_offset = pal_num
                    for x in range(self.tileWidth):
                        for y in range(self.tileHeight):
                            palOverlay[(row*self.tileHeight)+(y)][(col_offset*self.tileWidth)+(x)+(tileWidth*self.tileWidth)+16][0] = color[0]
                            palOverlay[(row*self.tileHeight)+(y)][(col_offset*self.tileWidth)+(x)+(tileWidth*self.tileWidth)+16][1] = color[1]
                            palOverlay[(row*self.tileHeight)+(y)][(col_offset*self.tileWidth)+(x)+(tileWidth*self.tileWidth)+16][2] = color[2]

            self.newImage = Image.fromarray(palOverlay)
            self.newImage.save(f'{fileout}_overlay.png')
            newPalImage = self.newImage.convert("P", dither=None, palette=Image.ADAPTIVE, colors=256)
            newPalImage.save(f'{fileout}_overlay_pal.png')

        try:
            with open(os.path.join(*os.path.split(fileout)[:-1],"built.txt"),"w") as f:
                f.write(f"Pal usage: {self.paletteMapTrace}\n")
                f.write(f'tile row {tileHeight}, col {tileWidth}\n')
                f.write(f'Total colors in an image: {nColours}\n')
                if self.noPalMap.get() == 0:
                    f.write(tempStr)
                f.write('done\n')
        except Exception as e: 
            self.error(f'Error: {e}')
            return False


        return True


    def matchTilePak(self, tile, palette_set):

        mask_count = 0
        match_pal = -1

        for p in range(len(palette_set)):
            mask = [[-1 for x in range(self.tileWidth)] for y in range(self.tileHeight)]
            mask_count = 0
            match_pal = p
            for row in range(self.tileHeight):
                for col in range(self.tileWidth):
                    for c in range(len(palette_set[p])):

                        tRed   = int(tile[row][col][0])
                        tGreen = int(tile[row][col][1])
                        tBlue  = int(tile[row][col][2])

                        cRed   = int(palette_set[p][c][0])
                        cGreen = int(palette_set[p][c][1])
                        cBlue  = int(palette_set[p][c][2])

                        if tRed == cRed and tGreen == cGreen and tBlue == cBlue:
                            mask[row][col] = c
                            mask_count += 1
                            break
            if mask_count == self.tileHeight*self.tileWidth:
                break
            else:
                mask_count = 0

        return mask_count == self.tileHeight*self.tileWidth, match_pal, mask

#.....................................
# END CLASS


def auto_int(val):
    val = int(val, (DECbase,HEXbase)['0x' in val])
    return val

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Convert TMX files to PCE maps',
                                      formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    runOptionsGroup = parser.add_argument_group('Run options', 'Run options for TMX converter')

    runOptionsGroup.add_argument('--filein',
                                 '-p',
                                 help='TODO')

    runOptionsGroup.add_argument('--palBlock',
                                 '-pb',
                                 help='TODO')

    runOptionsGroup.add_argument('--fileout',
                                 '-out',
                                 default='',
                                 help='TODO')

    runOptionsGroup.add_argument('--vram_addr',
                                 '-v',
                                 type=auto_int,
                                 default='0x0C00',
                                 help='TODO')

    runOptionsGroup.add_argument('--gui',
                                 '-g',
                                 action="store_true",
                                 help='TODO')

    runOptionsGroup.add_argument('--batch',
                                 '-b',
                                 type=str,
                                 default="",
                                 help='TODO')

    runOptionsGroup.add_argument('--forceRebuild',
                                 '-frb',
                                 action="store_true",
                                 help='TODO')



    args = parser.parse_args()

    runOptions = {}
    runOptions['filein']       = args.filein
    runOptions['palBlock']     = args.palBlock
    runOptions['fileout']      = args.fileout
    runOptions['vram_addr']    = args.vram_addr
    runOptions['args']         = args
    runOptions['batch']        = args.batch
    runOptions['forceRebuild'] = args.forceRebuild


    sys.exit( palConv(runOptions).process() == False)
