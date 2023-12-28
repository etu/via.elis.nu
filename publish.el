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
         :base-directory "./src"
         :publishing-function org-html-publish-to-html
         :publishing-directory "./output"
         :exclude ".*"
         :include [ "index.org" ]

         ;; Export options
         :html-preamble "<div id=\"logo\"><img src=\"/logo.png\" alt=\"Alt text\"></div>"
	     :html-head-extra "
           <meta name=\"referrer\" content=\"no-referrer\" />\n<link rel=\"stylesheet\" href=\"/style.css\" type=\"text/css\"/>

           <!-- Open graph tags -->
           <meta property=\"og:description\" content=\"Fördomsfri mötesplats för veganer och vegeterianer att prata om etiska värderingar, receptbyten, träning, hälsa med mera.\" />
           <meta property=\"og:image\" content=\"https://via.elis.nu/og-image.png\" />
           <meta property=\"og:locale\" content=\"sv\" />
           <meta property=\"og:site_name\" content=\"Vegan i Arvika\" />
           <meta property=\"og:title\" content=\"Vegan i Arvika - Startsida\" />
           <meta property=\"og:type\" content=\"website\" />
           <meta property=\"og:url\" content=\"https://via.elis.nu/\" />
           <meta name=\"twitter:card\" content=\"summary_large_image\" />
         "
         :html-container "article"            ; Set HTML container
         :html-doctype "html5"                ; Make it html5
         :html-head-include-default-style nil ; Disable default CSS styles
         :html-head-include-scripts nil       ; Disable default JS
         :html-validation-link nil            ; Disable HTML validation link
         :section-numbers nil                 ; Disable section numbers
         :with-toc nil                        ; Disable table of content
         :language "se")                      ; Set language

        ("site-posts"
         :base-directory "./src/posts"
         :publishing-function org-html-publish-to-html
         :publishing-directory "./output/posts"

         ;; Export options
         :html-preamble "<div id=\"logo\"><img src=\"/logo.png\" alt=\"Alt text\"></div><div><a href=\"/\">⬅️ Tillbaka till startsidan</a></div>"
	     :html-head-extra "
           <meta name=\"referrer\" content=\"no-referrer\" />\n<link rel=\"stylesheet\" href=\"/style.css\" type=\"text/css\"/>

           <!-- Open graph tags -->
           <meta property=\"og:image\" content=\"https://via.elis.nu/og-image.png\" />
           <meta property=\"og:locale\" content=\"sv\" />
           <meta property=\"og:site_name\" content=\"Vegan i Arvika\" />
           <meta property=\"og:type\" content=\"website\" />
           <meta name=\"twitter:card\" content=\"summary_large_image\" />
         "
         :html-container "article"            ; Set HTML container
         :html-doctype "html5"                ; Make it html5
         :html-head-include-default-style nil ; Disable default CSS styles
         :html-head-include-scripts nil       ; Disable default JS
         :html-validation-link nil            ; Disable HTML validation link
         :section-numbers nil                 ; Disable section numbers
         :with-toc nil                        ; Disable table of content
         :language "se")                      ; Set language

        ("site-static"
         :base-directory "./src"
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|asc\\|svg"
         :publishing-directory "./output"
         :publishing-function org-publish-attachment
         :exclude ".*"
         :include [ "og-image.png" "logo.png" "style.css" "CNAME" ])

        ("flyer"
         :base-directory "./src"
         :publishing-directory "./output"
         :publishing-function org-latex-publish-to-pdf
         :with-latex t
         :exclude ".*"
         :include [ "flyer.org" ])

        ("site" :components ("site-org" "site-posts" "site-static" "flyer"))))

(org-publish "site")



(provide 'publish)
;;; publish.el ends here
