;;; publish.el --- Build and Org blog -*- lexical-binding: t -*-

;; Copyright (C) 2023 Elis Hirwing <elis@hirwing.se>

;; Author: Elis Hirwing <elis@hirwing.se>

;; This file is not part of GNU Emacs.

;;; Code:

;; Org publish
(require 'org)
(require 'ox-publish)



(setq org-publish-project-alist
      '(("site-org"
         :base-directory "."
         :publishing-function org-html-publish-to-html
         :publishing-directory "./output"
         :exclude ".*"
         :include [ "index.org" ]

         ;; Export options
         :html-preamble "<div id=\"logo\"><img src=\"/logo.png\" alt=\"Alt text\"></div>"
	     :html-head-extra "<meta name=\"referrer\" content=\"no-referrer\" />\n<link rel=\"stylesheet\" href=\"/style.css\" type=\"text/css\"/>"
         :html-container "article"            ; Set HTML container
         :html-doctype "html5"                ; Make it html5
         :html-head-include-default-style nil ; Disable default CSS styles
         :html-head-include-scripts nil       ; Disable default JS
         :html-validation-link nil            ; Disable HTML validation link
         :section-numbers nil                 ; Disable section numbers
         :with-toc nil                        ; Disable table of content
         :language "se")                      ; Set language

        ("site-posts"
         :base-directory "./posts"
         :publishing-function org-html-publish-to-html
         :publishing-directory "./output/posts"

         ;; Export options
         :html-preamble "<div id=\"logo\"><img src=\"/logo.png\" alt=\"Alt text\"></div><div><a href=\"/\">⬅️ Tillbaka till startsidan</a></div>"
	     :html-head-extra "<meta name=\"referrer\" content=\"no-referrer\" />\n<link rel=\"stylesheet\" href=\"/style.css\" type=\"text/css\"/>"
         :html-container "article"            ; Set HTML container
         :html-doctype "html5"                ; Make it html5
         :html-head-include-default-style nil ; Disable default CSS styles
         :html-head-include-scripts nil       ; Disable default JS
         :html-validation-link nil            ; Disable HTML validation link
         :section-numbers nil                 ; Disable section numbers
         :with-toc nil                        ; Disable table of content
         :language "se")                      ; Set language

        ("site-static"
         :base-directory "."
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|asc\\|svg"
         :publishing-directory "./output"
         :publishing-function org-publish-attachment
         :exclude ".*"
         :include [ "logo.png" "style.css" ])

        ("print"
         :base-directory "."
         :publishing-directory "./output"
         :publishing-function org-latex-publish-to-pdf
         :with-latex t
         :exclude ".*"
         :include [ "print.org" ])

        ("site" :components ("site-org" "site-posts" "site-static" "print"))))

(org-publish "site")



(provide 'publish)
;;; publish.el ends here
