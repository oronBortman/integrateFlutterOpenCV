import cv2
import matplotlib.pyplot as plt
from matplotlib import pyplot


class Image:
    def __init__(self, img_path=None, img=None):
        if img is None:
            self.color_img = self.load_img(img_path)
        else:
            self.color_img = img
        self.gray = self.img_to_gray(self.color_img)
        self.blur_gray = cv2.GaussianBlur(self.gray, (3, 3), 0)
        self.height = len(self.color_img)
        self.width = len(self.color_img[0])

    def plot_img(self, gray=False):
        pyplot.switch_backend('Agg') #oron
        fig2 = plt.figure(figsize=(15, 15))  # create a 15 x 15 figure
        ax3 = fig2.add_subplot(111)
        ax3.imshow(self.color_img, interpolation='none') if not gray \
            else ax3.imshow(self.gray, interpolation='none', cmap='gray')

    @staticmethod
    def load_img(file_path):
        img = cv2.imread(file_path)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        return img

    @staticmethod
    def img_to_gray(img):
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        return img


def apply_threshold(img, threshold):
    img[img < threshold] = 0
    img[img >= threshold] = 255
    return img
