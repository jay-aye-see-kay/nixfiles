;; -*- lexical-binding: t; -*-

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 100 1000 1000))

(defun jdr/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'jdr/display-startup-time)

;; visual stuff
(setq inhibit-startup-message t)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(set-default 'truncate-lines t)

;; base font setup
(setq font-use-system-font t)
(let ((default-font-height (if (eq system-type 'darwin) 150 110)))
  (set-face-attribute 'default nil :height default-font-height))

;; Enable line numbering in `prog-mode'
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(require 'package)
;; makes unpure packages archives unavailable
(setq package-archives nil)
(setq package-enable-at-startup nil)
(package-initialize)

;; Automatically tangle our Emacs.org config file when we save it
;; FIXME don't hardcode nixfiles directory
(defun jdr/org-babel-tangle ()
  (when (string-equal (file-name-directory buffer-file-name)
                      (expand-file-name "~/nixfiles/users/jack/emacs/"))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'jdr/org-babel-tangle)))

(setq modus-themes-bold-constructs t
      modus-themes-italic-constructs t
      modus-themes-fringes 'subtle
      modus-themes-paren-match '(intense)
      modus-themes-prompts '(bold intense)
      modus-themes-completions 'opinionated
      modus-themes-org-blocks 'tinted-background
      modus-themes-scale-headings t
      modus-themes-region '(bg-only)
      modus-themes-syntax '(yellow-comments)
      modus-themes-headings
      '((1 . (overline background 1.4))
        (2 . (background 1.3))
        (3 . (bold 1.2))
        (t . (semilight 1.1))))
;; Load the light theme by default
(load-theme 'modus-operandi t)

(use-package no-littering)
;; no-littering doesn't set this by default so we must place
;; auto save files in the same path as it uses for sessions
(setq auto-save-file-name-transforms
      `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

;; NOTE: The first time you load your configuration on a new machine, you'll
;; need to run the following command interactively so that mode line icons
;; display correctly:

;; M-x all-the-icons-install-fonts
(use-package all-the-icons)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(recentf-mode t)
(setq recentf-max-saved-items 50)

(electric-pair-mode 1)

(add-hook
 'org-mode-hook
 (lambda ()
   (setq-local electric-pair-inhibit-predicate
               `(lambda (c)
                  (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))

(use-package helpful
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-key] . helpful-key)
  :config
  (global-set-key (kbd "C-c C-d") #'helpful-at-point))

;; modes with variable width font (docs + help)
(dolist (mode '(help-mode-hook
                helpful-mode-hook))
  (add-hook mode (lambda () (variable-pitch-mode))))

(use-package evil-goggles
  :ensure t
  :after evil
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

(use-package vundo
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols))

(defun project-vterm ()
  "Start a new vterm in project root (based on `project-shell`)"
  (interactive)
  (let* ((default-directory (project-root (project-current t)))
	 (default-project-vterm-name (project-prefixed-buffer-name "vterm"))
	 (vterm-buffer (get-buffer default-project-vterm-name)))
    (if (and vterm-buffer (not current-prefix-arg))
	(pop-to-buffer-same-window vterm-buffer)
      (vterm (generate-new-buffer-name default-project-vterm-name)))))

(use-package project
  :config
  (add-to-list 'project-switch-commands '(project-vterm "VTerm"))
  (add-to-list 'project-switch-commands '(magit-project-status "Magit"))
  :bind (("C-x p t" . project-vterm)
	 ("C-x p m" . magit-project-status)))

(use-package treemacs)

(use-package treemacs-evil
  :after (treemacs evil))

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once))

(use-package treemacs-magit
  :after (treemacs magit))

(use-package vertico
  :init
  (vertico-mode)
  (setq vertico-cycle t))

(use-package marginalia
  :config
  (marginalia-mode 1))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(savehist-mode 1)

;; A few more useful configurations...
(use-package emacs
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; Alternatively try `consult-completing-read-multiple'.
  (defun crm-indicator (args)
    (cons (concat "[CRM] " (car args)) (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  (setq read-extended-command-predicate
        #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t))

;; Optionally use the `orderless' completion style.
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package evil
  :ensure t
  :custom
  (evil-want-keybinding nil)
  (evil-want-C-u-scroll t)
  (evil-undo-system 'undo-redo)
  (evil-want-Y-yank-to-eol t)
  (evil-split-window-below t)
  (evil-vsplit-window-right t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal))

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;; Since I let evil-mode take over C-u for buffer scrolling, I need to re-bind
;; the universal-argument command to another key sequence
(global-set-key (kbd "C-M-u") 'universal-argument)

(use-package evil-collection
  :after evil
  :ensure t
  :custom
  (evil-collection-calendar-want-org-bindings t)
  (evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

(use-package evil-numbers
  :after evil
  :ensure t
  :config
  (define-key evil-normal-state-map (kbd "C-a") 'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-c +") 'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-c -") 'evil-numbers/dec-at-pt))

(use-package evil-org
  :ensure t
  :after org
  :hook (org-mode . (lambda () evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package evil-surround
  :ensure t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :ensure t
  :after evil
  :config (evil-commentary-mode))

(evil-define-key 'normal 'global (kbd "C-w C-h") 'evil-window-left)
(evil-define-key 'normal 'global (kbd "C-w C-j") 'evil-window-down)
(evil-define-key 'normal 'global (kbd "C-w C-k") 'evil-window-up)
(evil-define-key 'normal 'global (kbd "C-w C-l") 'evil-window-right)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package general
  :init
  (setq general-override-states
        '(insert emacs hybrid normal visual motion operator replace))
  :config
  (general-create-definer rune/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")
  (general-create-definer rune/quick-keys
    :keymaps '(normal)
    :prefix ","))

(general-unbind magit-mode-map "SPC")

(rune/leader-keys
  "SPC" 'project-find-file
  "p" project-prefix-map
  "gs" 'magit-status
  "hh" 'helpful-at-point
  "hf" 'helpful-function
  "hv" 'helpful-variable
  "hk" 'helpful-key
  "lf" 'eglot-format-buffer
  "lr" 'eglot-rename
  "la" 'eglot-code-actions)

;; setup avy like my hop.nvim setup
(use-package avy
  :after evil
  :config
  (evil-define-key 'normal 'global "s" 'evil-avy-goto-char))

;; quick keymaps like my vim setup
(rune/quick-keys
  "e" 'treemacs
  "b" 'consult-buffer
  "B" 'consult-project-buffer
  "f" 'find-file
  "l" 'consult-line
  "o" 'consult-recent-file
  "a" 'deadgrep
  "x" 'execute-extended-command)

(use-package deadgrep)
(use-package consult)
(use-package embark) ;; TODO understand and setup

(defun jdr/org-mode-setup ()
  (add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)
  (org-indent-mode 1)
  (visual-line-mode 1)
  (add-to-list 'org-export-backends 'md)

  (setq
   ;; Agenda styling
   ;; org-agenda-block-separator ?─
   org-agenda-time-grid
   '((daily today require-timed)
     (800 1000 1200 1400 1600 1800 2000)
     " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
   org-agenda-current-time-string
   "⭠ now ─────────────────────────────────────────────────")

  ;; override variable pitch fonts selectively
  (variable-pitch-mode 1)
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  )

(use-package org
  :hook (org-mode . jdr/org-mode-setup)
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda))
  :custom
  (org-startup-with-inline-images t)
  (org-auto-align-tags nil)
  (org-tags-column 0)
  (org-catch-invisible-edits 'show-and-error)
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  (org-pretty-entities t)
  (org-ellipsis "…")
  (org-agenda-start-with-log-mode t)
  (org-log-into-drawer t)
  (org-directory "~/Documents/org/")
  (org-agenda-files '("~/Documents/org/" "~/Documents/org/logbook"))
  (org-archive-location "~/Documents/org/archive.org::")
  (org-todo-keywords
   '((sequence "TODO(t)" "IN-PROGRESS(p!)" "WAITING(w@/!)"
               "|" "DONE(d!)" "CANCELLED(c!)")))
  (org-refile-targets
   `((,(directory-files-recursively "~/Documents/org/" "^[a-z0-9]*.org$") :maxlevel . 1)))
  :config
  ;; load org stuff up front rather than on the first time an org file is opened
  (org-load-modules-maybe t))

(use-package org-journal
  :ensure t
  :config
  (define-key org-mode-map (kbd "C-c C-j") 'org-journal-new-entry)
  (global-set-key (kbd "C-c C-S-j") 'org-journal-open-current-journal-file)
  (setq org-journal-dir "~/Documents/org/logbook/"
        org-journal-file-type 'weekly
        org-journal-file-format "week-%W.journal.org"
        org-journal-enable-agenda-integration t))

(use-package mermaid-mode)
(use-package ob-mermaid)

(with-eval-after-load 'org
  (add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
  (add-to-list 'org-src-lang-modes '("javascript" . js))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (js . t)
     (shell . t)
     (python . t)
     (mermaid . t)
     (latex . t)
     (plantuml . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes))

(with-eval-after-load 'org
  ;; This is needed as of Org 9.2
  (require 'org-tempo)

  (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("js" . "src js")))

(defun jdr/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook ((org-mode . jdr/org-mode-visual-fill)
         (markdown-mode . jdr/org-mode-visual-fill)))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0)
  (corfu-echo-documentation nil)
  (corfu-cycle t)
  :init
  (global-corfu-mode))

;; TODO render markdown from lsp? or is that an eglot thing?
(use-package corfu-doc
  :config
  (add-hook 'corfu-mode-hook #'corfu-doc-mode))

(use-package eglot
  :custom
  (eldoc-echo-area-use-multiline-p nil))

(use-package flymake
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package tree-sitter
  :ensure t
  :config
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :ensure t
  :after tree-sitter)

(use-package evil-textobj-tree-sitter
  :after evil
  :config
  (define-key evil-outer-text-objects-map "c"
    (evil-textobj-tree-sitter-get-textobj "class.outer"))
  (define-key evil-inner-text-objects-map "c"
    (evil-textobj-tree-sitter-get-textobj "class.inner"))
  (define-key evil-outer-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.inner")))

(use-package apheleia
  :config
  (add-to-list 'apheleia-formatters '(nixfmt . ("nixfmt")))
  (add-to-list 'apheleia-mode-alist '(nix-mode . nixfmt))
  (apheleia-global-mode +1))

(use-package typescript-mode
  :after tree-sitter
  :hook (typescript-mode . eglot-ensure)
  :config
  ;; choose this instead of tsx-mode so that eglot can automatically
  ;; figure out language server
  (define-derived-mode typescriptreact-mode typescript-mode
    "TypeScript TSX")
  ;; setup file type and tree sitter
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescriptreact-mode))
  (add-to-list 'tree-sitter-major-mode-language-alist '(typescriptreact-mode . tsx))
  (setq typescript-indent-level 2))

(use-package nix-mode
  :hook (nix-mode . eglot-ensure)
  :mode "\\.nix\\'")

(use-package rust-mode
  :hook (rust-mode . eglot-ensure)
  :custom
  ;; apheleia 1.2 doesn't work with rustfmt, so use rust-mode's formatting
  (rust-format-on-save t))

(use-package go-mode
  :hook (go-mode . eglot-ensure))

(use-package flymake-shellcheck
  :init
  (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

(add-hook 'sh-mode-hook 'eglot-ensure)

(use-package plantuml-mode)
(setq plantuml-executable-path "/usr/bin/plantuml")
(setq org-plantuml-executable-path "/usr/bin/plantuml")
(setq plantuml-default-exec-mode 'executable)
(setq org-plantuml-exec-mode 'executable)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :hook (markdown-mode . visual-line-mode))

(use-package yaml-mode
  :hook ((yaml-mode . display-line-numbers-mode)
         (yaml-mode . eglot-ensure))
  :config
  (add-to-list 'tree-sitter-major-mode-language-alist '(yaml-mode . yaml)))

(use-package yaml-pro
  :config
  (general-define-key
   :states 'normal
   :keymaps 'yaml-mode-map
   "C-k" 'yaml-pro-prev-subtree
   "C-j" 'yaml-pro-next-subtree
   "M-k" 'yaml-pro-move-subtree-up
   "M-j" 'yaml-pro-move-subtree-down))

(use-package docker
  :bind ("C-c d" . docker))

(use-package fish-mode
  :config
  (add-to-list 'tree-sitter-major-mode-language-alist '(fish-mode . fish)))

(use-package graphql-mode
  :config
  (add-to-list 'tree-sitter-major-mode-language-alist '(graphql-mode . graphql)))

(use-package prisma-mode
  :config
  (add-to-list 'eglot-server-programs '(prisma-mode . ("prisma-language-server" "--stdio")))
  (add-to-list 'tree-sitter-major-mode-language-alist '(prisma-mode . prisma)))

(use-package vimrc-mode
  :hook (vimrc-mode . eglot-ensure)
  :config
  (add-to-list 'auto-mode-alist '("\\.vim\\(rc\\)?\\'" . vimrc-mode))
  (add-to-list 'tree-sitter-major-mode-language-alist '(vim-mode . vim)))

(use-package magit)

(use-package vterm
  :custom
  (vterm-environment
   '("fish_term24bit=1"
     "fish_color_autosuggestion=#505050"
     "fish_color_cancel=#a60000"
     "fish_color_command=#5317ac"
     "fish_color_comment=#505050"
     "fish_color_cwd=#000000"
     "fish_color_cwd_root=#000000"
     "fish_color_end=#000000"
     "fish_color_error=#a60000"
     "fish_color_escape=#000000"
     "fish_color_history_current=#000000"
     "fish_color_host=#000000"
     "fish_color_host_remote=#000000"
     "fish_color_match=#000000"
     "fish_color_normal=#000000"
     "fish_color_operator=#721045"
     "fish_color_param=#000000"
     "fish_color_quote=#2544bb"
     "fish_color_redirection=#721045"
     "fish_color_search_match=#000000"
     "fish_color_selection=#000000"
     "fish_color_status=#000000"
     "fish_color_user=#000000")))

(use-package yasnippet
  :bind (("C-j" . tempel-expand)
         ("C-l" . tempel-next)
         ("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :config
(yas-global-mode 1))

(use-package pdf-tools)
