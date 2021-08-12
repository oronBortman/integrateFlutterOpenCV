import cv2
import numpy as np

from utils.fret_detection import remove_duplicate_vertical_lines
from utils.image import Image
from utils.image import apply_threshold


def string_detection(cropped_neck_img: Image, fret_lines):
    edges = cv2.Sobel(cropped_neck_img.blur_gray, cv2.CV_64F, 0, 1)
    edges = apply_threshold(img=edges, threshold=50)
    kernel = np.ones((5, 5), np.uint8)
    closing = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel)
    lines = cv2.HoughLinesP(image=closing.astype(np.uint8), rho=1, theta=np.pi / 180, threshold=15,
                            minLineLength=cropped_neck_img.width * 0.25, maxLineGap=20)
    lines = [line[0] for line in lines]
    lines = sorted(lines, key=lambda line: line[1])
    lines = remove_duplicate_horizontal_lines(lines=lines)
    for line in lines:
        cv2.line(cropped_neck_img.color_img, (fret_lines[0][0], line[1]), (fret_lines[-1][0], line[3]), (255, 0, 0), 2)
    cropped_neck_img.plot_img()

def remove_duplicate_horizontal_lines(lines):
    new_lines = []
    lines_pairwise = zip(lines[:len(lines)], lines[1:])
    for line1, line2 in lines_pairwise:
        if line2[1] - line1[1] > 3:
            new_lines.append(line1)
    if lines[-1][1] - new_lines[-1][1] > 3:
        new_lines.append(lines[-1])
    return new_lines
