(defsystem "monitor-home"
  :version "0.1.0"
  :author "Pedro Henrique Romano"
  :license "MIT"
  :depends-on (:serapeum
               :file-notify
               :mito
               :dbd-sqlite3)
  :components ((:module "src"
                :components
                ((:file "monitor-home"))))
  :description "")
