import getpass
import argparse
import qrcode



if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Optional app description')
    parser.add_argument('input')
    parser.add_argument('outputFile')
    args = parser.parse_args()
    
    
    img = qrcode.make(args.input)
    type(img)  # qrcode.image.pil.PilImage
    img.save(args.outputFile)


