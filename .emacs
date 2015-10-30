(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <down>")  'windmove-down)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <right>") 'windmove-right)
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
                           (split-window-vertically-n 5)
                           (toggle-truncate-lines)))
(global-set-key "\C-x|" '(lambda ()
                           (interactive)
                           (split-window-horizontally-n 5)
                           (toggle-truncate-lines)))


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
            (when (string-match "/postgres\\(ql\\)?/" buffer-file-name)
              (c-set-style "postgresql"))))


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
