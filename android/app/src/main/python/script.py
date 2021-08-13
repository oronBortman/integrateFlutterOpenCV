import io,os,sys,time,threading,ctypes,inspect,traceback, cv2
import join as j
from pathlib import Path
import random
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import PIL
from utils.fret_detection import fret_detection
from utils.image import Image
from utils.rotate_and_crop_neck import crop_neck
from utils.string_detection import string_detection

def _async_raise(tid, exctype):
    tid = ctypes.c_long(tid)
    if not inspect.isclass(exctype):
        exctype = type(exctype)
    res = ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, ctypes.py_object(exctype))
    if res == 0:
        raise ValueError("invalid thread id")
    elif res != 1:
        ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, None)
        raise SystemError("Timeout Exception")

def stop_thread(thread):
    _async_raise(thread.ident, SystemExit)

def text_thread_run(code):
    try:
        env={}
        exec(code, env, env)
    except Exception as e:
        print(e)

def getRandNum():
    return str(int(random.random() * 50))

#   This is the code to run Text functions...
def mainTextCode(code):
    succeed = True
    try:
        a = os.path.dirname(__file__)
        filename = os.path.join(a,"c.jpeg")
        img = cv2.imread(filename)
        img_with_lines = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        cv2.imwrite(filename, img_with_lines)

        '''
        details of the coordinates of the notes
        '''
        json_details = {
            "notes_coordinates": [
                {"x": getRandNum(), "y": getRandNum()},
                {"x": getRandNum(), "y": getRandNum()},
                {"x": getRandNum(), "y": getRandNum()},
            ],
            "numOfNotes": "3"}
        json_details  = str(json_details).replace("'","\"")

        im = PIL.Image.open(filename, 'r')
        PIL.Image.Image.save(im, filename)
        guitar = Image(str(Path(r"{}".format(filename))))
        cropped = crop_neck(guitar)
        fret_lines = fret_detection(cropped)
        string_detection(cropped_neck_img=cropped, fret_lines=fret_lines)
        plt.savefig(filename)
        succeed=True
    except:
        #print("failed")
        g=2 #dumb line for debugging - remove later
    if succeed:
        print(json_details)
