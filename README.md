This is a collection of various SVG helper functions:

* svg-opacity-gradient
* svg-outline
* svg-multi-line-text
* svg-smooth-line

Example usage:

```
(let* ((svg (svg-create 500 500)))
  (svg-embed svg "/music/01132-Secrets of the Beehive/display.jpg"
             "image/jpeg" nil
             :width 500
             :height 500)
  (svg-rectangle svg 50 50 400 400
                 :fill (svg-opacity-gradient
                        svg 'linear '((20 0.2 "red") (40 0.8 "white"))))
  (svg-multi-line-text svg '("Many" "Lines" "of Text")
                       :x 100
                       :y 100
                       :font-size 80 :fill "white"
                       :font-family "futura"
                       :filter (svg-outline svg 1 "black" 1))
  (svg-smooth-line svg
                   '((100 . 400)
                     (200 . 450)
                     (300 . 470)
                     (400 . 410))
                   :stroke-width 7 :stroke "red" :fill "none")
  (insert-image (svg-image svg)))
```

