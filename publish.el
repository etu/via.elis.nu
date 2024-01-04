;;; publish.el --- Build and Org blog -*- lexical-binding: t -*-

;; Copyright (C) 2023 Elis Hirwing <elis@hirwing.se>

;; Author: Elis Hirwing <elis@hirwing.se>

;; This file is not part of GNU Emacs.

;;; Code:

;; Org publish
(require 'org)
(require 'ox-publish)



(setq org-publish-project-alist
      '(("flyer"
         :base-directory "."
         :publishing-directory "./output"
         :publishing-function org-latex-publish-to-pdf
         :with-latex t
         :exclude ".*"
         :include [ "flyer.org" ])))

(org-publish "flyer")



(provide 'publish)
;;; publish.el ends here
