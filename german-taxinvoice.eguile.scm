<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
<?scm
(let ((x 42)) ; only here to allow (define)s
              ; i.e. to avoid "Bad define placement" error

;; german-taxinvoice.eguile.scm  0.04
;; GnuCash report template called from taxinvoice.scm 0.02
;; (c) 2009 Chris Dennis chris@starsoftanalysis.co.uk
;;
;; $Author: chris $ $Date: 2011/12/10 01:29:00 $ $Revision: 1.34 $
;; $Author: chris $ $Date: 2009/07/23 10:42:08 $ $Revision: 1.33 $
;;
;; This file is a mixture of HTML and Guile --
;; see eguile-gnc.scm for details.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
;; 02111-1307 USA

  (define (display-report opt-invoice owner endowner ownertype)
    ;; Main function that creates the tax invoice report
    (let* (; invoice and company details
           (invoiceid  (gncInvoiceGetID         opt-invoice))
           (book       (gncInvoiceGetBook       opt-invoice))
           (postdate   (gncInvoiceGetDatePosted opt-invoice))
           (duedate    (gncInvoiceGetDateDue    opt-invoice))
           (billingid  (gncInvoiceGetBillingID  opt-invoice))
           (notes      (gncInvoiceGetNotes      opt-invoice))
           (terms      (gncInvoiceGetTerms      opt-invoice))
           (termsdesc  (gncBillTermGetDescription terms))
           (lot        (gncInvoiceGetPostedLot  opt-invoice))
           (txn        (gncInvoiceGetPostedTxn  opt-invoice))
           (currency   (gncInvoiceGetCurrency   opt-invoice))
           (entries    (gncInvoiceGetEntries    opt-invoice))
           (splits     '())
           (slots      (qof-book-get-slots book))
           (coyname    (coy-info slots gnc:*company-name*))
           (coycontact (coy-info slots gnc:*company-contact*))
           (coyaddr    (coy-info slots gnc:*company-addy*))
           (coyid      (coy-info slots gnc:*company-id*))
           (coyphone   (coy-info slots gnc:*company-phone*))
           (coyfax     (coy-info slots gnc:*company-fax*))
           (coyurl     (coy-info slots gnc:*company-url*))
           (coyemail   (coy-info slots gnc:*company-email*))
           (owneraddr  (gnc:owner-get-name-and-address-dep owner))
           (ownerid    (gnc:owner-get-owner-id owner))
           (billcontact (gncAddressGetName (gnc:owner-get-address owner)))
           ; flags and counters
           (discount?  #f) ; any discounts on this invoice?
           (tax?       #f) ; any taxable entries on this invoice?
           (taxtables? #t) ; are tax tables available in this version?
           (payments?  #f) ; have any payments been made on this invoice?
           (units?     #f) ; does any row specify units?
           (qty?       #f) ; does any row have qty <> 1?
           (spancols1  2)  ; for total line
           (spancols2  2)  ; for subtotal line
           (position   1)) ; for position number

      ; load splits, if any
      (if (not (null? lot))
        (set! splits
          (sort-list (gnc-lot-get-split-list lot) ; sort by date
                     (lambda (s1 s2)
                       (let ((t1 (xaccSplitGetParent s1))
                             (t2 (xaccSplitGetParent s2)))
                         (< (car (gnc-transaction-get-date-posted t1))
                            (car (gnc-transaction-get-date-posted t2))))))))

      ; pre-scan invoice entries to look for discounts and taxes
      (for entry in entries do
          (let ((action    (gncEntryGetAction entry))
                (qty       (gncEntryGetQuantity entry))
                (discount  (gncEntryGetInvDiscount entry))
                (taxtable  (gncEntryGetInvTaxTable entry)))
            (if (not (string=? action ""))
              (set! units? #t))
            (if (not (= (gnc-numeric-to-double qty) 1.0))
              (set! qty? #t))
            (if (not (gnc-numeric-zero-p discount)) (set! discount? #t))
            ;(if taxable - no, this flag is redundant
            (if (not (eq? taxtable '()))
              (begin ; presence of a tax table means it's taxed
                (set! tax? #t)
                (let ((ttentries (gncTaxTableGetEntries taxtable)))
                  (if (string-prefix? "#<swig-pointer PriceList" (object->string ttentries))
                    ; error in SWIG binding -- disable display of tax details
                    ; (see http://bugzilla.gnome.org/show_bug.cgi?id=573645)
                    (set! taxtables? #f))))))) ; hack required until Swig is fixed

      ; pre-scan invoice splits to see if any payments have been made
      (for split in splits do
          (let* ((t (xaccSplitGetParent split)))
            (if (not (equal? t txn))
              (set! payments? #t))))

?>

<html>
	<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
	<title><?scm:d (_ "Invoice") ?>: <?scm:d invoiceid ?></title>
	<?scm (if css? (begin ?>
		<link rel="stylesheet" href="<?scm:d opt-css-file ?>" type="text/css">
	<?scm )) ?>
</head>
<body>

<div id="titelUndUntertitel">
<?scm ;(if (access? opt-logofile R_OK) (begin ?>
;    <img class="logo" src="<?scm:d opt-logofile ?>" alt="" />
;  <?scm ))
?>
  <p><span class="titel"><span><?scm:d (or coyname (_ "Company Name")) ?></span></span><br /><span class="untertitel"><span><?scm:d opt-company-slogan ?></span></span></p>
</div>

<div id="register">
  <dl>
    <?scm (if coyaddr (begin ?>
      <dt class="coyaddr"><span><?scm:d (_"Mail") ?></span></dt>
      <dd class="coyaddr"><span><?scm:d (nl->br coyaddr) ?></span></dd>
    <?scm )) ?>
    <?scm (if coyphone (begin ?>
      <dt class="coyphone"><span><?scm:d (_"Phone") ?></span></dt>
      <dd class="coyphone"><span><?scm:d coyphone ?></span></dd>
    <?scm )) ?>
    <?scm (if coyfax (begin ?>
      <dt class="coyfax"><span><?scm:d (_"Fax") ?></span></dt>
      <dd class="coyfax"><span><?scm:d coyfax ?></span></dd>
    <?scm )) ?>
    <?scm (if coyemail (begin ?>
      <dt class="coyemail"><span><?scm:d (_"eMail") ?></span></dt>
      <dd class="coyemail"><span><?scm:d coyemail ?></span></dd>
    <?scm )) ?>
    <?scm (if coyurl (begin ?>
      <dt class="coyurl"><span><?scm:d (_"Web") ?></span></dt>
      <dd class="coyurl"><span><?scm:d coyurl ?></span></dd>
    <?scm )) ?>
<!--
    <?scm (if coycontact (begin ?>
      <dt class="coycontact"><span><?scm:d (_"Ansprechpartner") ?></span></dt>
      <dd class="coycontact"><span><?scm:d coycontact ?></span></dd>
    <?scm )) ?>
-->
    <?scm (if ( equal? postdate (cons 0 0)) (begin ) (begin ?>
      <dt class="postdate"><span><?scm:d (_"Invoice Date") ?></span></dt>
      <dd class="postdate"><span><?scm:d ( gnc-print-date postdate ) ?></span></dd>
      <dt class="duedate"><span><?scm:d (_"Due Date") ?></span></dt>
      <dd class="duedate"><span><?scm:d ( gnc-print-date duedate ) ?></span></dd>
    <?scm )) ?>
    <dt class="ownerid"><span><?scm:d (_"Customer Id" ) ?></span></dt>
    <dd class="ownerid"><span><?scm:d ownerid ?></span></dd>
  </dl>
</div>

<div id="backaddress">
  <?scm (if coyaddr (begin ?>
    <p><?scm:d coyname ?><?scm:d delimiter ?><?scm:d (nl->delimiter coyaddr) ?></p>
  <?scm )) ?>
</div>

<div id="toaddress">
  <?scm (if (not (string=? owneraddr "")) (begin ?>
      <?scm:d (nl->br owneraddr) ?>
  <?scm )) ?>
</div>


<?scm (if (equal? postdate (cons 0 0)) (begin ?>
  <h1><span><?scm:d (_ "Invoice in progress...") ?></span></h1>
<?scm ) (begin ?>
  <h1><span><?scm:d (_ "Invoice" ) ?>: <?scm:d invoiceid ?></span></h1>
<?scm )) ?>


<?scm (if (not (string=? termsdesc "")) (begin ?>
  <p><?scm:d termsdesc ?></p>
<?scm )) ?>

<?scm (if (not (string=? billingid "")) (begin ?>
  <p>Your ref: <?scm:d billingid ?></p>
<?scm )) ?>

<div id="inhalt">
<!-- tabelle hier -->
<table width="100%"  border="0" cellspacing="0">
  <thead>
    <tr valign="bottom">
      <th align="center" ><?scm:d (_ "Pos.") ?></th>
      <th colspan="2" align="left" width="80%"><?scm:d (_ "Description") ?></th>
      <?scm (if units? (begin ?>
        <th align="left"><?scm:d opt-units-heading ?></th>
        <?scm (set! spancols1 (+ spancols1 1))
              (set! spancols2 (+ spancols2 1)))) ?>
      <?scm (if (or units? qty?) (begin ?>
        <th align="right"><?scm:d opt-qty-heading ?></th>
        <?scm (set! spancols1 (+ spancols1 1))
              (set! spancols2 (+ spancols2 1)))) ?>
      <?scm (if (or units? qty? discount?) (begin ?>
        <th align="right"><?scm:d opt-unit-price-heading ?></th>
        <?scm (set! spancols1 (+ spancols1 1))
              (set! spancols2 (+ spancols2 1)))) ?>
      <?scm (if discount? (begin ?>
        <th align="right"><?scm:d opt-disc-rate-heading ?></th>
        <th align="right"><?scm:d opt-disc-amount-heading ?></th>
        <?scm (set! spancols1 (+ spancols1 2))
              (set! spancols2 (+ spancols2 1)))) ?>
      <?scm (if (and tax? taxtables?) (begin ?>
        <th align="right"><?scm:d opt-net-price-heading ?></th>
        <th align="right"><?scm:d opt-tax-rate-heading ?></th>
        <th align="right"><?scm:d opt-tax-amount-heading ?></th>
        <?scm (set! spancols1 (+ spancols1 3))
              (set! spancols2 (+ spancols2 0)))) ?>
      <th align="right"><?scm:d opt-total-price-heading ?></th>
    </tr>
  </thead>

  <tbody> <!-- display invoice entry lines, keeping running totals -->
    <?scm
      (let ((tax-total (gnc:make-commodity-collector))
            (sub-total (gnc:make-commodity-collector))
            (dsc-total (gnc:make-commodity-collector))
            (inv-total (gnc:make-commodity-collector)))
        (for entry in entries do
            (let ((qty       (gncEntryGetQuantity entry))
                  (each      (gncEntryGetInvPrice entry))
                  (action    (gncEntryGetAction entry))
                  (rval      (gncEntryReturnValue entry #t))
                  (rdiscval  (gncEntryReturnDiscountValue entry #t))
                  (rtaxval   (gncEntryReturnTaxValue entry #t))
                  (disc      (gncEntryGetInvDiscount entry))
                  (disctype  (gncEntryGetInvDiscountType entry))
                  (acc       (gncEntryGetInvAccount entry))
                  (taxable   (gncEntryGetInvTaxable entry))
                  (taxtable  (gncEntryGetInvTaxTable entry)))
              (inv-total 'add currency rval)
              (inv-total 'add currency rtaxval)
              (tax-total 'add currency rtaxval)
              (sub-total 'add currency rval)
              (dsc-total 'add currency rdiscval)
    ?>
    <tr valign="top">
      <!-- td align="center"><?scm:d (gnc-print-date (gncEntryGetDate entry)) ?></td -->
      <td align="right" class="value"><?scm:d position ?><?scm (set! position (+ position 1)) ?></td>
      <td colspan="2" align="left" class="description"><?scm:d (gncEntryGetDescription entry) ?></td>
      <!-- td align="left"><?scm:d (gncEntryGetNotes entry) ?></td -->
      <?scm (if units? (begin ?>
        <td align="left" class="unit"><?scm:d action ?></td>
      <?scm )) ?>
      <?scm (if (or units? qty?) (begin ?>
        <td align="right" class="quantity value"><?scm:d (fmtnumeric qty) ?></td>
      <?scm )) ?>
      <?scm (if (or units? qty? discount?) (begin ?>
        <td align="right" class="unitPrice value"><?scm:d (fmtmoney currency each) ?></td>
      <?scm )) ?>
      <?scm (if discount? (begin ?>
        <?scm (if (equal? disctype GNC-AMT-TYPE-VALUE) (begin ?>
          <td align="right" class="discountRate value"><?scm:d (gnc:monetary->string (gnc:make-gnc-monetary currency disc)) ?></td>
        <?scm ) (begin ?>
          <td align="right" class="discountRate value"><?scm:d (fmtnumeric disc) ?>%</td>
        <?scm )) ?>
        <td align="right" class="discountValue value"><?scm:d (fmtmoney currency rdiscval) ?></td>
      <?scm )) ?>
      <?scm (if (and tax? taxtables?) (begin ?>
        <td align="right" class="nettoPrice value"><?scm:d (fmtmoney currency rval) ?></td>
        <td align="right" class="taxRate value"><?scm (taxrate taxable taxtable currency) ?></td>
        <td align="right" class="taxValue value"><?scm:d (fmtmoney currency rtaxval) ?></td>
      <?scm )) ?>
      <!-- TO DO: need an option about whether to display the tax-inclusive total? -->
      <td align="right" class="totalPrice value"><?scm:d (fmtmoney currency (gnc-numeric-add rval rtaxval GNC-DENOM-AUTO GNC-RND-ROUND)) ?></td>
    </tr>
    <?scm )) ?>

    <!-- display subtotals row -->
    <?scm (if (or tax? discount? payments?) (begin ?>
      <tr valign="top">
        <th align="left" class="subtotal" colspan="<?scm:d (+ spancols2 1) ?>"><?scm:d opt-subtotal-heading ?></th>
        <?scm (if discount? (begin ?>
          <td align="right" class="subtotal value discountValue"><?scm (display-comm-coll-total dsc-total #f) ?></td>
        <?scm )) ?>
        <?scm (if (and tax? taxtables?) (begin ?>
          <td align="right" class="subtotal value nettoPrice"><?scm (display-comm-coll-total sub-total #f) ?></td>
          <td align="right" class="subtotal value"> </td>
          <td align="right" class="subtotal value taxValue"><?scm (display-comm-coll-total tax-total #f) ?></td>
        <?scm )) ?>
        <td align="right" class="subtotal value totalPrice"><?scm (display-comm-coll-total inv-total #f) ?></td>
      </tr>
    <?scm )) ?>

    <!-- payments -->
    <?scm
      (if payments?
        (for split in splits do
            (let ((t (xaccSplitGetParent split)))
              (if (not (equal? t txn)) ; don't process the entry itself as a split
                (let ((c (xaccTransGetCurrency t))
                      (a (xaccSplitGetValue    split)))
                  (inv-total 'add c a)
    ?>
    <tr valign="top">
      <td align="center" colspan="2" width="9em" class="payment value"><?scm:d (gnc-print-date (gnc-transaction-get-date-posted t)) ?></td>
      <td align="left" colspan="<?scm:d (- spancols1 1) ?>" class="payment"><?scm:d opt-payment-recd-heading ?></td>
      <td align="right" class="payment value"><?scm:d (fmtmoney c a) ?></td>
    </tr>
    <?scm ))))) ?>

    <!-- total row -->
    <tr valign="top">
      <td align="left" class="total" colspan="<?scm:d (+ spancols1 1) ?>"><strong><?scm:d opt-amount-due-heading ?></strong></td>
      <td align="right" class="total value final"><strong><?scm (display-comm-coll-total inv-total #f) ?></strong></td>
    </tr>

  </tbody>
    <?scm ) ?> <!-- end of (let) surrounding table body -->

</table>

<?scm (if (not (string=? notes "")) (begin ?>
  <p class="notes"><?scm:d (nl->br notes) ?></p>
<?scm )) ?>

<?scm (if (not (string=? opt-extra-notes "")) (begin ?>
  <p class="extraNotes"><?scm:d (nl->br opt-extra-notes) ?></p>
<?scm )) ?>
</div>

<div id="legalform">
  <dl>
    <dt class="kind"><span><?scm:d opt-legal-kind-title ?></span></dt>
    <dd class="kind"><span><?scm:d opt-legal-kind ?></span></dd>
    <dt class="kind-add"><span><?scm:d opt-legal-kind-add-title ?></span></dt>
    <dd class="kind-add"><span><?scm:d (nl->br opt-legal-kind-add) ?></span></dd>
  </dl>
</div>
<div id="coyid">
  <dl>
    <dt class="coyid"><span><?scm:d opt-legal-coyid-title ?></span></dt>
    <dd class="coyid"><span><?scm:d coyid ?></span></dd>
  </dl>
</div>
<div id="bankaccount">
  <p><?scm:d opt-bank-connection-title ?></p>
  <dl>
    <dt class="name"><span><?scm:d opt-bank-name-title ?></span></dt>
    <dd class="name"><span><?scm:d opt-bank-name ?></span></dd>
    <dt class="nationalcode"><span><?scm:d opt-bank-nationalcode-title ?></span></dt>
    <dd class="nationalcode"><span><?scm:d opt-bank-nationalcode ?></span></dd>
    <dt class="swiftcode"><span><?scm:d opt-bank-swiftcode-title ?></span></dt>
    <dd class="swiftcode"><span><?scm:d opt-bank-swiftcode ?></span></dd>
    <dt class="accountnumber"><span><?scm:d opt-bank-accountnumber-title ?></span></dt>
    <dd class="accountnumber"><span><?scm:d opt-bank-accountnumber ?></span></dd>
    <dt class="ibancode"><span><?scm:d opt-bank-ibancode-title ?></span></dt>
    <dd class="ibancode"><span><?scm:d opt-bank-ibancode ?></span></dd>
  </dl>
</div>



<?scm )) ; end of display-report function

  ; 'mainline' code: check for a valid invoice, then display the report
  (if (null? opt-invoice)
    (begin
      (display (string-append "<h2>" (_ "Tax Invoice") "</h2>"))
      (display (string-append "<p>" (_ "No invoice has been selected -- please use the Options menu to select one.") "</p>")))
    (let* ((owner     (gncInvoiceGetOwner  opt-invoice))
           (endowner  (gncOwnerGetEndOwner owner))
           (ownertype (gncOwnerGetType     endowner)))
      (if (not (eqv? ownertype GNC-OWNER-CUSTOMER))
        (begin
          (display (string-append "<h2>" (_ "Tax Invoice") "</h2>"))
          (display (string-append "<p>" (_ "This report is designed for customer (sales) invoices only. Please use the Options menu to select an <em>Invoice</em>, not a Bill or Expense Voucher.") "</p>")))
        (display-report opt-invoice owner endowner ownertype))))

?>
</div>
</body>
</html>
<?scm
) ; end of enclosing let
?>
