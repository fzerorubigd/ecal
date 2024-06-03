#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import logging
from display import epd7in5b_V2
import time
import argparse
import pathlib
from PIL import Image,ImageDraw,ImageFont

def main():
    parser = argparse.ArgumentParser(description='Render images on the screen')
    parser.add_argument('black', type=pathlib.Path,help='black mask')
    parser.add_argument('red', type=pathlib.Path, help='red mask')
    args = parser.parse_args()
    
    try:
        logging.info("Refresh screen")
        epd = epd7in5b_V2.EPD()
        logging.info("init and Clear")
        epd.init()
        epd.Clear()

        bImg = Image.open(os.path.abspath(args.black))
        rImg = Image.open(os.path.abspath(args.red))

        epd.display(epd.getbuffer(bImg),epd.getbuffer(rImg))
        time.sleep(2)
        logging.info("done")
    except IOError as e:
        logging.info(e)
        
    except KeyboardInterrupt:    
        logging.info("ctrl + c:")
        epd7in5b_V2.epdconfig.module_exit(cleanup=True)
        exit()


if __name__ == '__main__':
  main()