(add-to-list 'load-path "/home/masahiko/.emacs.d/package.el")
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
;;(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives  '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(package-initialize)

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <down>")  'windmove-down)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c g") 'rgrep)
(which-function-mode 1)
(setq make-backup-files nil)
;;; .#* とかのバックアップファイルを作らない
(setq auto-save-default nil)
(global-set-key "\C-h" 'delete-backward-char)

(setq diff-auto-refine-mode nil)
(defun diff-mode-setup-faces ()
  ;; 追加された行は緑で表示
  (set-face-attribute 'diff-added nil
                      :foreground "dark green")
  ;; 削除された行は赤で表示
  (set-face-attribute 'diff-removed nil
                      :foreground "dark red")
  ;; 文字単位での変更箇所は色を反転して強調
  (set-face-attribute 'diff-refine-change nil
                      :foreground nil :background nil
                      :weight 'bold :inverse-video t))
(add-hook 'diff-mode-hook 'diff-mode-setup-faces)

(global-set-key (kbd "C-c t") 'toggle-truncate-lines)

;;git gutter
;;(add-to-list 'load-path "/home/masahiko/.emacs.d/git-gutter+.el")
(require 'git-gutter+)
(global-git-gutter+-mode t)
(setq git-gutter+-separator-sign "|")
(set-face-foreground 'git-gutter+-separator "yellow")
(setq git-gutter+-modified-sign "=")
(setq git-gutter+-added-sign "+")    ;; multiple character is OK
(setq git-gutter+-deleted-sign "-")
(set-face-foreground 'git-gutter+-added "green")
(set-face-foreground 'git-gutter+-deleted "red")
(global-set-key (kbd "C-x n") 'git-gutter+-next-hunk)
(global-set-key (kbd "C-x p") 'git-gutter+-previous-hunk)
(global-set-key (kbd "C-x v") 'git-gutter+-show-hunk)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x r") 'git-gutter+-revert-hunks)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x t") 'git-gutter+-stage-hunks)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x c") 'git-gutter+-commit)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x C") 'git-gutter+-stage-and-commit)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x C-y") 'git-gutter+-stage-and-commit-whole-buffer)
		       ;;(define-key git-gutter+-mode-map (kbd "C-x U") 'git-gutter+-unstage-whole-buffer))

(defun split-window-vertically-n (num_wins)
  (interactive "p")
  (if (= num_wins 2)
      (split-window-vertically)
    (progn
      (split-window-vertically
       (- (window-height) (/ (window-height) num_wins)))
      (split-window-vertically-n (- num_wins 1)))))
(defun split-window-horizontally-n (num_wins)
  (interactive "p")
  (if (= num_wins 2)
      (split-window-horizontally)
    (progn
      (split-window-horizontally
       (- (window-width) (/ (window-width) num_wins)))
      (split-window-horizontally-n (- num_wins 1)))))
(global-set-key "\C-x-" '(lambda ()
                           (interactive)
                           (split-window-vertically-n 3)
                           (toggle-truncate-lines)))
(global-set-key "\C-x|" '(lambda ()
                           (interactive)
                           (split-window-horizontally-n 3)
                           (toggle-truncate-lines)))
(global-set-key "\C-cg" 'rgrep)


;; -*- mode: emacs-lisp -*-

;; This file contains code to set up Emacs to edit PostgreSQL source
;; code.  Copy these snippets into your .emacs file or equivalent, or
;; use load-file to load this file directly.
;;
;; Note also that there is a .dir-locals.el file at the top of the
;; PostgreSQL source tree, which contains many of the settings shown
;; here (but not all, mainly because not all settings are allowed as
;; local variables).  So for light editing, you might not need any
;; additional Emacs configuration.


;;; C files

;; Style that matches the formatting used by
;; src/tools/pgindent/pgindent.  Many extension projects also use this
;; style.
(c-add-style "postgresql"
             '("bsd"
               (c-auto-align-backslashes . nil)
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)
                                   (label . -)
                                   (statement-case-open . +)))
               (fill-column . 78)
               (indent-tabs-mode . t)
               (tab-width . 4)))

(add-hook 'c-mode-hook 
         (defun postgresql-c-mode-hook ()
	   (c-set-style "postgresql")))

;;; Perl files

;; Style that matches the formatting used by
;; src/tools/pgindent/perltidyrc.
(defun pgsql-perl-style ()
  "Perl style adjusted for PostgreSQL project"
  (interactive)
  (setq perl-brace-imaginary-offset 0)
  (setq perl-brace-offset 0)
  (setq perl-continued-brace-offset 4)
  (setq perl-continued-statement-offset 4)
  (setq perl-indent-level 4)
  (setq perl-label-offset -2)
  (setq tab-width 4))

(add-hook 'perl-mode-hook
          (defun postgresql-perl-mode-hook ()
             (when (string-match "/postgres\\(ql\\)?/" buffer-file-name)
               (pgsql-perl-style))))


;;; documentation files

(add-hook 'sgml-mode-hook
          (defun postgresql-sgml-mode-hook ()
             (when (string-match "/postgres\\(ql\\)?/" buffer-file-name)
               (setq fill-column 78)
               (setq indent-tabs-mode nil)
               (setq sgml-basic-offset 1))))


;;; Makefiles

;; use GNU make mode instead of plain make mode
(add-to-list 'auto-mode-alist '("/postgres\\(ql\\)?/.*Makefile.*" . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("/postgres\\(ql\\)?/.*\\.mk\\'" . makefile-gmake-mode))
(add-to-list 'load-path "/home/masahiko/.emacs.d/go-mode")
(add-to-list 'load-path "/home/masahiko/.emacs.d/auto-complete")
(add-to-list 'load-path "/home/masahiko/.emacs.d/popup-el")
(require 'go-mode)
(require 'go-mode-autoloads)
(add-hook 'go-mode-hook
	  '(lambda()
		  (setq c-basic-offset 4)
		  (setq indent-tabs-mode t)
		  (local-set-key (kbd "M-.") 'godef-jump)
		  (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)
		  (local-set-key (kbd "C-C i") 'go-goto-imports)
		  (local-set-key (kbd "C-c d") 'godoc)))
(add-hook 'before-save-hook 'gofmt-before-save)
(require 'go-autocomplete)
(require 'auto-complete-config)

(global-hl-line-mode t)                   ;; 現在行をハイライト
(show-paren-mode t)                       ;; 対応する括弧をハイライト
(setq show-paren-style 'mixed)            ;; 括弧のハイライトの設定。
(transient-mark-mode t)                   ;; 選択範囲をハイライト

(defun markdown-preview-by-eww ()
  (interactive)
  (message (buffer-file-name))
  (call-process "grip" nil nil nil
		(buffer-file-name)
		"--export"
		"/tmp/grip.html")
  (let ((buf (current-buffer)))
    (eww-open-file "/tmp/grip.html")
    (switch-to-buffer buf)
    (pop-to-buffer "*eww*")))
(global-set-key "\C-x\C-d" 'markdown-preview-by-eww)

(cua-mode t)
(setq cua-enable-cua-keys nil)
(global-set-key "\C-x\C-\ " 'cua-set-rectangle-mark)

(add-to-list 'load-path "~/.emacs.d/rust-mode/")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))

(setq-default show-trailing-whitespace t)

;(split-window-horizontally)
;(split-window-horizontally)
;(balance-windows)


; Load smart mode line
(add-to-list 'load-path "/home/masahiko/.emacs.d/rich-minority")
(require 'rich-minority)
(add-to-list 'load-path "/home/masahiko/.emacs.d/smart-mode-line")

(line-number-mode t) ;; display line number
(column-number-mode t) ;; display column number
;; mode-line-format customization
(setq-default mode-line-format
	      '("="
		mode-line-modified
		(line-number-mode "L%l-")
		(column-number-mode "C%c-")
		(-3 . "%p")    ; position 表示はいらないかなっと
;		mode-line-mule-info
;		mode-line-frame-identification
		(which-func-mode ("" which-func-format "-"))
		mode-line-buffer-identification
;		" "
;		" %[("
;		mode-name
;		mode-line-process
;		minor-mode-alist
;		"%n" ")%]-"
		"-%-")
	      )
(setq-default default-mode-line-format mode-line-format)

(setq imenu-create-index-function
      (lambda ()
	(let ((end))
	  (beginning-of-buffer)
	  (re-search-forward "^%%")
	  (forward-line 1)
	  (setq end (save-excursion (re-search-forward "^%%") (point)))
	  (loop while (re-search-forward "^\\([a-z].*?\\)\\s-*\n?\\s-*:" end t)
		collect (cons (match-string 1) (point))))))

(add-to-list 'load-path "/home/masahiko/.emacs.d/irony-mode")
(add-to-list 'load-path "/home/masahiko/.emacs.d/company-irony")
(require 'irony)
(eval-after-load 'company
  '(add-to-list 'company-backends 'company-irony))
(ac-config-default)


(require 'auto-complete-config)
(ac-config-default)
(add-to-list 'ac-modes 'text-mode)         ;; text-modeでも自動的に有効にする
(add-to-list 'ac-modes 'fundamental-mode)  ;; fundamental-mode
(add-to-list 'ac-modes 'org-mode)
(add-to-list 'ac-modes 'yatex-mode)
(ac-set-trigger-key "TAB")
(setq ac-use-menu-map t)       ;; 補完メニュー表示時にC-n/C-pで補完候補選択
(setq ac-use-fuzzy t)          ;; 曖昧マッチ

(require 'helm)
(require 'helm-config)
(helm-mode 1)

;; helm setting
(require 'helm-etags-plus)
(defun helm-etags-plus-myselect(&optional arg)
  "Find Tag using `etags' and `helm'"
  (interactive "P")
  (cond
   ((equal arg '(4))                  ;C-u
    (helm-etags-plus-select-internal)) ;waiting for you input pattern
   (t (helm-etags-plus-select-internal ""))))  ;use thing-at-point as symbol

(global-set-key "\M-." 'helm-etags-plus-myselect)
;(global-set-key "\M-." 'helm-etags-plus-select)
;;go back directly
(global-set-key "\M-*" 'helm-etags-plus-history-go-back)
;;list all visited tags
(global-set-key "\M-," 'helm-etags-plus-history)
;;go forward directly
(global-set-key "\M-/" 'helm-etags-plus-history-go-forward)
(define-key helm-find-files-map (kbd "TAB") 'helm-execute-persistent-action)
(define-key helm-read-file-map (kbd "TAB") 'helm-execute-persistent-action)


(add-to-list 'load-path "/home/masahiko/.emacs.d/helm-gdb")
(require 'helm-gdb)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (helm-migemo migemo projectile helm-etags-plus git-gutter+))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
