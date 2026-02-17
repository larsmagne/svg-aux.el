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

;;; Code:

(provide 'svg-aux)

;;; svg-aux.el ends here
