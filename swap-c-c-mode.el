;;; swap-c-c-mode.el --- Dynamically swap C-c bindings with another key

;; Copyright (C) 2021 Dustin Ross

;; Author: Dustin Ross <dustinross@live.com>
;; Keyword: convenience
;; Version: 1.0
;; URL: https://github.com/mope-life/swap-c-c-mode

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file defines a global minor mode which helps to bind what
;; would normally be bound to C-c, `mode-specific-map', to another
;; key.  It tries to do this as invisibily as possible, so that help
;; buffers, internal documentation, etc., will be fooled into thinking
;; that nothing is amiss.  In addition to binding `mode-specific-map'
;; to another key, this mode can set C-c to be anything you want, most
;; likely `kill-ring-save' or a related command.

;; Use the autoloaded `swap-c-c-mode' to turn the mode on.  Customize
;; where to move your C-c map to, and what new binding to give C-c,
;; `M-x customize-group RET swap-c-c RET'.

;;; Code:

(defgroup swap-c-c nil
  "For the swap-c-c-mode minor mode."
  :group 'convenience
  :prefix "swap-c-c-")

(defcustom swap-c-c-new-binding 'kill-ring-save
  "To what C-c should be newly bound."
  :type 'symbol
  :group 'swap-c-c)

(defcustom swap-c-c-new-key ""
  "Where to move the map that used to be bound to C-c."
  :type 'key-sequence
  :group 'swap-c-c)

(defvar swap-c-c--emulation-map nil
  "The map that rebinds C-c and `swap-c-c-new-key'.")

(defvar swap-c-c--emulation-map-alist
  '((swap-c-c-mode keymap))
  "Variable placed in `emulation-mode-map-alists' for `swap-c-c-mode'.")

(defun swap-c-c--update-map ()
  "Do binding for `swap-c-c-emulation-map'."
  (setq swap-c-c--emulation-map (make-sparse-keymap))
  (define-key swap-c-c--emulation-map (kbd "C-c") swap-c-c-new-binding)
  (define-key swap-c-c--emulation-map swap-c-c-new-key
    (list 'menu-item "" nil
	  :visible nil
	  :filter 'swap-c-c--dynamic-bind))
  (setq swap-c-c--emulation-map-alist
	(list (cons 'swap-c-c-mode swap-c-c--emulation-map))))

(defun swap-c-c--dynamic-bind (&optional _)
  "Return the map normally associated with C-c."
  ;; Temporarily turn mode off so that correct map can be found.
  (let (swap-c-c-mode)
    (key-binding (kbd "C-c"))))

(defun swap-c-c--help-advice (fn &rest r)
  "Let various help functions find the correct keys for things."
  ;; Temporarily set new key to a static keymap.
  (define-key swap-c-c--emulation-map swap-c-c-new-key
    (key-binding swap-c-c-new-key))
  (let ((res (apply fn r)))
    (swap-c-c--update-map)
    res))

(defun swap-c-c--setup ()
  (swap-c-c--update-map)
  (advice-add 'where-is-internal :around 'swap-c-c--help-advice)
  (advice-add 'substitute-command-keys :around 'swap-c-c--help-advice)
  (advice-add 'describe-bindings :around 'swap-c-c--help-advice))

(defun swap-c-c--teardown ()
  (advice-remove 'where-is-internal 'swap-c-c--help-advice)
  (advice-remove 'substitute-command-keys 'swap-c-c--help-advice)
  (advice-remove 'describe-bindings 'swap-c-c--help-advice))

;;;###autoload
(define-minor-mode swap-c-c-mode nil
  :init-value nil
  :global t
  :group 'swap-c-c
  :lighter (" C-c=>" (:eval (key-description swap-c-c-new-key)))
  (if swap-c-c-mode
      (swap-c-c--setup)
    (swap-c-c--teardown)))

(add-to-list 'emulation-mode-map-alists 'swap-c-c--emulation-map-alist)

;;; swap-c-c-mode.el ends here
