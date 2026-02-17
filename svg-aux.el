;;; svg-aux.el --- more SVG utility functions  -*- lexical-binding: t; -*-
;; Copyright (C) 2026 Lars Magne Ingebrigtsen

;; Author: Lars Magne Ingebrigtsen <larsi@gnus.org>
;; Keywords: extensions, processes

;; This file is not part of GNU Emacs.

;; svg-aux.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; svg-aux.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

(defvar svg--id-counter 1)

(defun svg-outline (svg size color opacity)
  "Create an outline filter of SIZE, using COLOR and OPACITY.
Returns the name of the filter -- use this as the `:filter'
parameter on the SVG element that should have an outline."
  (let* ((counter (cl-incf svg--id-counter))
	 (id (format "outline-%d" counter)))
    (dom-append-child
     svg
     (dom-node 'filter `((id . ,id))
	       (dom-node 'feMorphology
			 `((in . "SourceAlpha")
			   (result . ,(format "DILATED-%d" counter))
			   (operator . "dilate")
			   (radius . ,(format "%s" size))))
	       (dom-node 'feFlood
			 `((flood-color . ,color)
			   (flood-opacity . ,(format "%s" opacity))
			   (result . ,(format "FLOOD-%d" counter))))
	       (dom-node 'feComposite
			 `((in . ,(format "FLOOD-%d" counter))
			   (in2 . ,(format "DILATED-%d" counter))
			   (operator . "in")
			   (result . ,(format "OUTLINE-%d" counter))))
	       (dom-node
		'feMerge nil
		(dom-node 'feMergeNode `((in . ,(format "OUTLINE-%d" counter))))
		(dom-node 'feMergeNode `((in . "SourceGraphic"))))))
    (format "url(#%s)" id)))

(defun svg-opacity-gradient (svg id type stops)
  "Add an opacity gradient with ID to SVG.
TYPE is `linear' or `radial'.  STOPS is a list of percentage/opacity
pairs."
  (svg--def
   svg
   (apply
    'dom-node
    (if (eq type 'linear)
	'linearGradient
      'radialGradient)
    `((id . ,id)
      (x1 . 0)
      (x2 . 0)
      (y1 . 0)
      (y2 . 1))
    (mapcar
     (lambda (stop)
       (dom-node 'stop `((offset . ,(format "%s%%" (car stop)))
			 (stop-opacity . ,(cdr stop)))))
     stops))))

(defun svg-multi-line-text (svg texts &rest args)
  "Add TEXTS to SVG.
The line will be advanced by 1em per text."
  (let ((a (svg--arguments svg args)))
    (svg--append
     svg
     (apply
      'dom-node 'text `(,@a)
      (cl-loop for text in texts
	       collect (dom-node 'tspan `((dy . "1.0em")
					  (x . ,(cdr (assoc 'x a))))
				 (svg--encode-text text)))))))

(defun svg--smooth-line-piece (a b)
  (let ((length-x (- (car b) (car a)))
	(length-y (- (cdr b) (cdr a))))
    (list :length (sqrt (+ (expt length-x 2) (expt length-y 2)))
	  :angle (atan length-y length-x))))

(defun svg--smooth-line-bezier-control-point (current previous next reverse)
  (let* ((previous (or previous current))
	 (next (or next current))
	 (line (svg--smooth-line-piece previous next))
	 (angle (+ (cl-getf line :angle)
		   (if reverse
		       float-pi
		     0)))
	 (smoothing 0.2)
	 (length (* (cl-getf line :length) smoothing)))
    (cons (+ (car current) (* (cos angle) length))
	  (+ (cdr current) (* (sin angle) length)))))

(defun svg--smooth-line-bezier (i points)
  (let ((cps (svg--smooth-line-bezier-control-point
	      (elt points (- i 1))
	      (elt points (- i 2))
	      (elt points i)
	      nil))
	(cpe (svg--smooth-line-bezier-control-point
	      (elt points i)
	      (elt points (1- i))
	      (elt points (1+ i))
	      t)))
    (format "C %s,%s %s,%s %s,%s"
	    (car cps) (cdr cps)
	    (car cpe) (cdr cpe)
	    (car (elt points i)) (cdr (elt points i)))))

(defun svg-smooth-line (svg points &rest args)
  "Add POINTS to SVG as a smooth line."
  (setq args
	`(:d
	  ,(string-join
	    (cl-loop for point in points
		     for i from 0
		     collect (if (zerop i)
				 (format "M %s,%s" (car point) (cdr point))
			       (svg--smooth-line-bezier i points)))
	    " ")
	  ,@args))
  (svg--append
   svg (dom-node 'path `(,@(svg--arguments svg args)))))

(provide 'svg-aux)

;;; svg-aux.el ends here
