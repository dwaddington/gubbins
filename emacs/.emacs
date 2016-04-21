(global-font-lock-mode)
(set-background-color "NavyBlue")
(set-face-foreground font-lock-function-name-face "Yellow")
(set-foreground-color "White")
(set-cursor-color "Yellow");
(toggle-truncate-lines)
(setq-default c-basic-offset 2)

; rebind keys
(global-set-key [C-tab] 'eme-unbury-buffer)     ; control-tab
(global-set-key [f9] 'do-compile)
(global-set-key [S-f9] 'do-full-compile)
(global-set-key [S-delete] 'delete-region)
(global-set-key [f2] 'do-print)

(defun do-compile () "Execute build"
        (interactive)
        (progn (compile "make -j")))
;        (progn (compile "make -C ~/genode/genode/build.nova32 -j")))

(defun do-full-compile() "Executed full build"
        (interactive)
        (progn (compile "make clean; make -j")))   
;        (progn (compile "make -C ~/genode/genode/build.nova32 clean; make -j")))   

(defun do-print() "Normal PS print"
  (interactive)
  (progn (global-font-lock-mode)(ps-print-buffer)(global-font-lock-mode))
)

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))


; gnuplot
;
(add-to-list 'auto-mode-alist '("\\.gplot\\'" . gnuplot-mode))

;
; textlint
;
;(add-to-list 'load-path "~/.emacs.d/textlint/")
;(load "textlint.el")

;
; doxymacs
;
(autoload 'doxymacs-mode "doxymacs" "Deal with doxygen." t)
(add-hook 'c-mode-common-hook'doxymacs-mode)

;(add-to-list 'auto-mode-alist '("\\.snpl\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))
;(add-to-list 'auto-mode-alist '("\\.str\\'" . stratego-mode))

;
; used for iterating buffers
;
(defun eme-unbury-buffer ()
  "Switch to the last (normal) buffer in the buffer list, Should be
inverse of bury-buffer"
  (interactive)
  (let ((bl (reverse (buffer-list))))
    (while bl
        (let* ((buffer (car bl))
        (name (buffer-name buffer)))
                (cond ((string= (substring name 0 1) " ")) ;; ignore hidden buff
                (t (progn (switch-to-buffer buffer) (setq bl nil))))
        (setq bl (cdr bl))))))
; kill scratch


;
; set up printing
;

;;
;; Define postscript print options for NT
;;
;;(require 'ps-print)
;;(setq ps-paper-type 'ps-a4)
;;(setq ps-font-size 6)
;;(setq ps-lpr-command "print")
;;(setq ps-lpr-switches '("/D:\\\\CENTRAL_PRINT\\egaphoto"))
;;(setq ps-lpr-buffer "d:\\psspool.ps")
;;(setq ps-print-color-p nil)        ;; Disable colour emulation on printer

;;
;; Setup postscript print commands for NT and map to keys
;;
(defun nt-ps-print-buffer-with-faces ()
  (interactive)
  (ps-print-buffer-with-faces ps-lpr-buffer)
  (shell-command
   (apply 'concat (append (list ps-lpr-command " ")
                          ps-lpr-switches
                          (list " " ps-lpr-buffer))))
)
(define-key global-map "\C-cb" 'nt-ps-print-buffer-with-faces)

(defun nt-ps-print-region-with-faces ()
  (interactive)
  (ps-print-region-with-faces (mark) (point) ps-lpr-buffer)
  (shell-command
   (apply 'concat (append (list ps-lpr-command " ")
                          ps-lpr-switches
                          (list " " ps-lpr-buffer))))
)
(define-key global-map "\C-cr" 'nt-ps-print-region-with-faces)

; semantic/CEDET configuration
(load-file "/opt/cedet/cedet-1.1/common/cedet.el")
(global-ede-mode 1)                      ; Enable the Project management system
(semantic-load-enable-code-helpers)      ; Enable prototype help and smart completion 
(global-srecode-minor-mode 1)            ; Enable template insertion menu
(semantic-load-enable-minimum-features)

(defvar c-files-regex ".*\\.\\(c\\|cpp\\|h\\|hpp\\)"
  "A regular expression to match any c/c++ related files under a directory")

(defun semantic-parse-dir (root regex)
  "
   Parse all source files under a root directory. Arguments:
   -- root: The full path to the root directory
   -- regex: A regular expression against which to match all files in the directory
  "
  (let (
        ;;make sure that root has a trailing slash and is a dir
        (root (file-name-as-directory root))
        (files (directory-files root t ))
       )
    ;; remove current dir and parent dir from list
    (setq files (delete (format "%s." root) files))
    (setq files (delete (format "%s.." root) files))
    (while files
      (setq file (pop files))
      (if (not(file-accessible-directory-p file))
          ;;if it's a file that matches the regex we seek
          (progn (when (string-match-p regex file)
               (save-excursion
                 (semanticdb-file-table-object file))
           ))
          ;;else if it's a directory
          (semantic-parse-dir file regex)
      )
     )
  )
)

(defun semantic-parse-current-dir (regex)
  "
   Parses all files under the current directory matching regex
  "
  (semantic-parse-dir (file-name-directory(buffer-file-name)) regex)
)

(defun lk-parse-curdir-c ()
  "
   Parses all the c/c++ related files under the current directory
   and inputs their data into semantic
  "
  (interactive)
  (semantic-parse-current-dir c-files-regex)
)

(defun lk-parse-dir-c (dir)
  "Prompts the user for a directory and parses all c/c++ related files
   under the directory
  "
  (interactive (list (read-directory-name "Provide the directory to search in:")))
  (semantic-parse-dir (expand-file-name dir) c-files-regex)
)


(global-semantic-idle-completions-mode)

(defun custom-cedet-hook ()
;  (local-set-key [(control return)] 'semantic-ia-complete-symbol)
;  (local-set-key "\C-c?" 'semantic-ia-complete-symbol-menu)
;  (local-set-key "\C-c>" 'semantic-complete-analyze-inline)
;  (local-set-key [(control .)] 'semantic-ia-fast-jump)
  (local-set-key "\C-t" 'semantic-analyze-proto-impl-toggle)
  (local-set-key "\C-j" 'semantic-ia-fast-jump)
  (local-set-key "\C-r" 'semantic-symref)
  (local-set-key [(control .)] 'semantic-complete-analyze-inline) 
;;semantic-ia-complete-symbol-menu

)

(add-hook 'c-mode-common-hook 'custom-cedet-hook)


(semantic-add-system-include "/usr/include" 'c++-mode)
(semantic-add-system-include "/usr/include" 'c-mode)
(semantic-add-system-include "/usr/include/efi" 'c++-mode)
(semantic-add-system-include "/usr/include/efi" 'c-mode)


;;
;; ctags
;;
(setq path-to-ctags "/usr/bin/ctags")

(defun create-tags (dir-name)
    "Create tags file."
    (interactive "DDirectory: ")
    (shell-command
     (format "ctags -f %s -R %s" path-to-ctags (directory-file-name dir-name)))
  )

;; Options Menu Settings

;; End of Options Menu Settings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-compression-mode t nil (jka-compr))
 '(case-fold-search t)
 '(current-language-environment "UTF-8")
 '(default-input-method "latin-9-prefix")
 '(global-font-lock-mode t nil (font-lock))
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(setq indent-tabs-mode)
 '(show-paren-mode t)
 '(tab-stop-list (quote (2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80)))
 '(tab-width 2))



(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "NavyBlue" :foreground "White" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 109 :width normal :foundry "unknown" :family "DejaVu Sans Mono")))))

