(defun fib (n)
  (if (or (= n 1) (= n 2))
      1
      (let ((a 1) (b 1))
        (loop for i from 3 to n do
          (let ((next (+ a b)))
            (setf a b)
            (setf b next)))
        b)))

(format t "~D~%" (fib 60)) 