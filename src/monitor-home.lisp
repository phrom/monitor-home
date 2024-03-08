(defpackage phr.monitor-home
  (:use :cl)
  (:local-nicknames (:notify :org.shirakumo.file-notify))
  (:export :main :build))
(in-package :phr.monitor-home)

(mito:deftable file ()
  ((name :col-type :text))
  (:primary-key name))

(defun connect-to-database (db)
  (mito:connect-toplevel :sqlite3 :database-name db)
  (dolist (table '(file))
    (mito:ensure-table-exists table)))

(defun notify (name)
  (uiop:run-program (list "notify-send"
                          (format nil "New file in $HOME: ~a" name))))

(defun handle-notify-event (path change)
  (let ((name (pathname-name path)))
    (cond
      ((eq change :create)
       (mito:create-dao 'file :name name)
       (notify name))
      ((eq change :delete)
       (let ((file (mito:find-dao 'file :name name)))
         (when file (mito:delete-dao file)))))))

(defun directory-entry-names (dir)
  (append (mapcar #'pathname-name (uiop:directory-files dir))
          (serapeum:~>>
           (uiop:subdirectories dir)
           (mapcar #'pathname-directory)
           (mapcar #'last)
           (mapcar #'car))))

(defun load-initial-files (dir)
  (let ((first-run (= (mito:count-dao 'file) 0))
        (names (mapcar #'pathname-name (directory-entry-names dir))))
    (dolist (name names)
      (unless (mito:find-dao 'file :name name)
        (mito:create-dao 'file :name name)
        (unless first-run (notify name))))
    (let ((removed-names (set-difference (mapcar #'file-name (mito:retrieve-dao 'file)) names
                                         :test #'string=)))
      (dolist (name removed-names)
        (mito:delete-by-values 'file :name name)))))

(defun main ()
  (let ((home (car (directory (uiop:getenv "HOME"))))
        (database (serapeum:~>>
                   (uiop:getenv "XDG_DATA_HOME") directory car
                   (merge-pathnames "monitor-home.db"))))
    (connect-to-database database)
    (load-initial-files home)
    (notify:watch home)
    (notify:with-events (path change :timeout t)
      (handle-notify-event path change))))

;; (main)

(defun build ()
  (sb-ext:save-lisp-and-die
   "monitor-home"
   :executable t
   :compression t
   :toplevel #'main))
