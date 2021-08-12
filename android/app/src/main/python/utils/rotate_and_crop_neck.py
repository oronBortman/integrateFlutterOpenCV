from utils.image import Image
from itertools import chain
from math import inf
from operator import itemgetter
from statistics import median
import cv2
import numpy as np

from utils.image import apply_threshold


def crop_neck(guitar_image: Image) -> Image:
    # TODO: improve
    rotated = rotate_img(guitar_image)

    edges = cv2.Canny(rotated.blur_gray, 20, 180)
    mag = get_magnitude(edges)
    mag = apply_threshold(img=mag, threshold=127)

    lines = cv2.HoughLinesP(mag, 1, np.pi / 180, 15, 50, 50)
    y = chain.from_iterable(itemgetter(1, 3)(line[0]) for line in lines)
    y_sort = list(sorted(y))
    y_differences = [0]

    first_y = 0
    last_y = inf

    for i in range(len(y_sort) - 1):
        y_differences.append(y_sort[i + 1] - y_sort[i])
    for i in range(len(y_differences) - 1):
        if y_differences[i] == 0:
            last_y = y_sort[i]
            if i > 3 and first_y == 0:
                first_y = y_sort[i]

    return Image(img=rotated.color_img[first_y - 10:last_y + 10])


def rotate_img(guitar_image: Image) -> Image:
    med_slope = calc_med_slope(guitar_image)
    angle = med_slope * 55
    image_center = tuple(np.array(guitar_image.color_img.shape[1::-1]) / 2)
    rot_mat = cv2.getRotationMatrix2D(image_center, angle, 1.0)
    rotated = cv2.warpAffine(guitar_image.color_img, rot_mat, guitar_image.color_img.shape[1::-1],
                             flags=cv2.INTER_LINEAR)
    return Image(img=rotated)


def calc_med_slope(guitar_image: Image) -> float:
    edges = cv2.Canny(guitar_image.blur_gray, 30, 150)
    mag = get_magnitude(edges)
    lines = cv2.HoughLinesP(mag, 1, np.pi / 180, 15, 50, 50)
    slopes = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        slope = float(y2 - y1) / (float(x2 - x1) + 0.001)
        slopes.append(slope)
    return median(slopes)


def get_magnitude(img):
    gradient_X = cv2.Sobel(img, cv2.CV_64F, 1, 0)
    gradient_Y = cv2.Sobel(img, cv2.CV_64F, 0, 1)
    magnitude = np.sqrt((gradient_X ** 2) + (gradient_Y ** 2))
    magnitude = cv2.convertScaleAbs(magnitude)
    return magnitude
