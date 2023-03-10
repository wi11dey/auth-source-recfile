;;; auth-source-recfile.el --- use passwords stored in GNU Recutils databases -*- lexical-binding: t -*-

;; Author: Will Dey
;; Maintainer: Will Dey
;; Version: 1.0.0
;; Package-Requires: ((rec-mode "1.9.0"))
;; Homepage: homepage
;; Keywords: keywords


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; commentary

;;; Code:

(require 'seq)
(require 'binhex)
(require 'rec-mode)

(defgroup auth-source-recfile ()
  ""
  :group 'auth-source)

(defcustom auth-source-recfile-use-recsel nil
  ""
  :type 'boolean)

(defcustom auth-source-recfile-use-recins nil
  ""
  :type 'boolean)

(defcustom auth-source-recfile-recsel-query nil
  "")

(defcustom auth-source-recfile-big-endian nil
  ""
  :type 'boolean)

(defcustom auth-source-recfile-decrypt t
  ""
  :type 'boolean)

(defcustom auth-source-recfile-cache t
  ""
  :type 'boolean)

;; Based on http://www.thoughtstuff.com/rme/crc.lisp, written by Written by R. Matthew Emerson <rme@acm.org> in August 1999, and placed in the public domain:
(defconst auth-source-recfile-crc32-table
  [#x00000000 #x77073096 #xEE0E612C #x990951BA #x076DC419 #x706AF48F
	      #xE963A535 #x9E6495A3 #x0EDB8832 #x79DCB8A4 #xE0D5E91E #x97D2D988 
	      #x09B64C2B #x7EB17CBD #xE7B82D07 #x90BF1D91 #x1DB71064 #x6AB020F2 
	      #xF3B97148 #x84BE41DE #x1ADAD47D #x6DDDE4EB #xF4D4B551 #x83D385C7 
	      #x136C9856 #x646BA8C0 #xFD62F97A #x8A65C9EC #x14015C4F #x63066CD9 
	      #xFA0F3D63 #x8D080DF5 #x3B6E20C8 #x4C69105E #xD56041E4 #xA2677172 
	      #x3C03E4D1 #x4B04D447 #xD20D85FD #xA50AB56B #x35B5A8FA #x42B2986C 
	      #xDBBBC9D6 #xACBCF940 #x32D86CE3 #x45DF5C75 #xDCD60DCF #xABD13D59 
	      #x26D930AC #x51DE003A #xC8D75180 #xBFD06116 #x21B4F4B5 #x56B3C423 
	      #xCFBA9599 #xB8BDA50F #x2802B89E #x5F058808 #xC60CD9B2 #xB10BE924 
	      #x2F6F7C87 #x58684C11 #xC1611DAB #xB6662D3D #x76DC4190 #x01DB7106 
	      #x98D220BC #xEFD5102A #x71B18589 #x06B6B51F #x9FBFE4A5 #xE8B8D433 
	      #x7807C9A2 #x0F00F934 #x9609A88E #xE10E9818 #x7F6A0DBB #x086D3D2D 
	      #x91646C97 #xE6635C01 #x6B6B51F4 #x1C6C6162 #x856530D8 #xF262004E 
	      #x6C0695ED #x1B01A57B #x8208F4C1 #xF50FC457 #x65B0D9C6 #x12B7E950 
	      #x8BBEB8EA #xFCB9887C #x62DD1DDF #x15DA2D49 #x8CD37CF3 #xFBD44C65 
	      #x4DB26158 #x3AB551CE #xA3BC0074 #xD4BB30E2 #x4ADFA541 #x3DD895D7 
	      #xA4D1C46D #xD3D6F4FB #x4369E96A #x346ED9FC #xAD678846 #xDA60B8D0 
	      #x44042D73 #x33031DE5 #xAA0A4C5F #xDD0D7CC9 #x5005713C #x270241AA 
	      #xBE0B1010 #xC90C2086 #x5768B525 #x206F85B3 #xB966D409 #xCE61E49F 
	      #x5EDEF90E #x29D9C998 #xB0D09822 #xC7D7A8B4 #x59B33D17 #x2EB40D81 
	      #xB7BD5C3B #xC0BA6CAD #xEDB88320 #x9ABFB3B6 #x03B6E20C #x74B1D29A 
	      #xEAD54739 #x9DD277AF #x04DB2615 #x73DC1683 #xE3630B12 #x94643B84 
	      #x0D6D6A3E #x7A6A5AA8 #xE40ECF0B #x9309FF9D #x0A00AE27 #x7D079EB1 
	      #xF00F9344 #x8708A3D2 #x1E01F268 #x6906C2FE #xF762575D #x806567CB 
	      #x196C3671 #x6E6B06E7 #xFED41B76 #x89D32BE0 #x10DA7A5A #x67DD4ACC 
	      #xF9B9DF6F #x8EBEEFF9 #x17B7BE43 #x60B08ED5 #xD6D6A3E8 #xA1D1937E 
	      #x38D8C2C4 #x4FDFF252 #xD1BB67F1 #xA6BC5767 #x3FB506DD #x48B2364B 
	      #xD80D2BDA #xAF0A1B4C #x36034AF6 #x41047A60 #xDF60EFC3 #xA867DF55 
	      #x316E8EEF #x4669BE79 #xCB61B38C #xBC66831A #x256FD2A0 #x5268E236 
	      #xCC0C7795 #xBB0B4703 #x220216B9 #x5505262F #xC5BA3BBE #xB2BD0B28 
	      #x2BB45A92 #x5CB36A04 #xC2D7FFA7 #xB5D0CF31 #x2CD99E8B #x5BDEAE1D 
	      #x9B64C2B0 #xEC63F226 #x756AA39C #x026D930A #x9C0906A9 #xEB0E363F 
	      #x72076785 #x05005713 #x95BF4A82 #xE2B87A14 #x7BB12BAE #x0CB61B38 
	      #x92D28E9B #xE5D5BE0D #x7CDCEFB7 #x0BDBDF21 #x86D3D2D4 #xF1D4E242 
	      #x68DDB3F8 #x1FDA836E #x81BE16CD #xF6B9265B #x6FB077E1 #x18B74777 
	      #x88085AE6 #xFF0F6A70 #x66063BCA #x11010B5C #x8F659EFF #xF862AE69 
	      #x616BFFD3 #x166CCF45 #xA00AE278 #xD70DD2EE #x4E048354 #x3903B3C2 
	      #xA7672661 #xD06016F7 #x4969474D #x3E6E77DB #xAED16A4A #xD9D65ADC 
	      #x40DF0B66 #x37D83BF0 #xA9BCAE53 #xDEBB9EC5 #x47B2CF7F #x30B5FFE9 
	      #xBDBDF21C #xCABAC28A #x53B39330 #x24B4A3A6 #xBAD03605 #xCDD70693 
	      #x54DE5729 #x23D967BF #xB3667A2E #xC4614AB8 #x5D681B02 #x2A6F2B94 
	      #xB40BBE37 #xC30C8EA1 #x5A05DF1B #x2D02EF8D])
(defun auth-source-recfile-crc32 (sequence)
  (logxor (seq-reduce (lambda (crc char)
			(logxor (aref auth-source-recfile-crc32-table
				      (logand #xff (logxor crc char)))
				(ash crc -8)))
		      sequence
		      #xffffffff)
	  #xffffffff))

(defconst auth-source-recfile-salt-size 4)
(defconst auth-source-recfile-key-size 16)
(defconst auth-source-recfile-block-size 16)
(defun auth-source-recfile-decrypt (input password)
  (if (string-prefix-p "encrypted-" input)
      (progn
	(unless (gnutls-available-p)
	  (user-error "Emacs was not compiled with GnuTLS enabled"))
	(let* ((password-chars (string-to-list password))
	       (key (apply #'unibyte-string
			   (take 16
				 ;; Make list a cycle first:
				 (nconc password-chars
					password-chars))))
	       (decoded (base64-decode-string
			 (substring-no-properties input
						  (length "encrypted-"))))
	       (encrypted (substring-no-properties decoded 0 -4))
	       (salt (substring-no-properties decoded -4))
	       (iv (concat salt
			   (apply #'unibyte-string
				  (number-sequence 4 (1- auth-source-recfile-block-size)))))
	       (decrypted (car (gnutls-symmetric-decrypt 'AES-128-CBC key iv encrypted)))
	       (output (substring-no-properties decrypted 0 -4))
	       (crc (substring-no-properties decrypted -4)))
	  (clear-string key)
	  (clear-string decrypted)
	  (unless (= (auth-source-recfile-crc32 output)
		     (if auth-source-recfile-big-endian
			 (binhex-string-big-endian crc)
		       (binhex-string-little-endian crc)))
	    (error "Decryption failed: CRC does not match"))
	  output))
    input))

(defun auth-source-recfile-load (recfile)
  (let ((password (read-passwd (concat "Password for " recfile ": ")))) ; TODO use password-cache
    (unwind-protect
	(if auth-source-recfile-use-recsel
	    (rec-query)
	  (with-temp-buffer
	    (insert-file-contents recfile)
	    (rec-query)
	    (apply call-process-region
		   password ; String input.
		   nil ; (Ignored.)
		   rec-recsel ; Program.
		   nil ; Don't attempt to delete input region.
		   t ; Output to current buffer.
		   nil ; Don't redisplay as output is inserted.
		   "-c" file
		   "--print-sexps"
		   auth-source-recfile-recsel-args)
	    (goto-char (point-min))
            (insert "(")
            (goto-char (point-max))
            (insert ")")
	    (dolist (record (read (point-min-marker)))
	      ))
	  (rec-goto-type-first-rec type) ; TODO type
	  (rec-parse-record)
	  )
      (clear-string password))))

(defun auth-source-recfile-create ()
  )

(defun auth-source-recfile-search ()
  )

(defun auth-source-recfile-parser (entry)
  (when (stringp entry)
    (setq entry `(:source ,(:recfile entry))))
  (let ((source (plist-get entry :source)))
    (when (and (stringp source)
	       (equal "rec" (file-name-extension source)))
      (auth-source-backend
       source
       :source source
       :type 'recfile
       :create-function auth-source-recfile-create
       :search-function auth-source-recfile-search
       :data (make-hash-table :test equal)))))

(provide 'auth-source-recfile)

;;; auth-source-recfile.el ends here
