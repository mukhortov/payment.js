payment = {}
payment = (method, element, args...) ->
  return if !element
  payment.fn[method].apply(element, args)

payment.fn = {}

# Utils

defaultFormat = /(\d{1,4})/g

cards = [
  # Debit cards must come first, since they have more
  # specific patterns than their credit-card equivalents.
  {
      type: 'visaelectron'
      pattern: /^4(026|17500|405|508|844|91[37])/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'maestro'
      pattern: /^(5(018|0[23]|[68])|6(39|7))/
      format: defaultFormat
      length: [12..19]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'forbrugsforeningen'
      pattern: /^600/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'dankort'
      pattern: /^5019/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  # Credit cards
  {
      type: 'visa'
      pattern: /^4/
      format: defaultFormat
      length: [13, 16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'mastercard'
      pattern: /^5[0-5]/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'amex'
      pattern: /^3[47]/
      format: /(\d{1,4})(\d{1,6})?(\d{1,5})?/
      length: [15]
      cvcLength: [3..4]
      luhn: true
  }
  {
      type: 'dinersclub'
      pattern: /^3[0689]/
      format: defaultFormat
      length: [14]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'discover'
      pattern: /^6([045]|22)/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'unionpay'
      pattern: /^(62|88)/
      format: defaultFormat
      length: [16..19]
      cvcLength: [3]
      luhn: false
  }
  {
      type: 'jcb'
      pattern: /^35/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
]

onEvent = (element, eventName, callback) ->
  element.addEventListener eventName, (e) ->
    ifPreventDefault = callback(e)
    e.preventDefault() if !ifPreventDefault
    return ifPreventDefault
  , false
  return

trim = (str) ->
  (str + '').replace(/^\s+|\s+$/g, '')

cardFromNumber = (num) ->
  num = (num + '').replace(/\D/g, '')
  return card for card in cards when card.pattern.test(num)

cardFromType = (type) ->
  return card for card in cards when card.type is type

luhnCheck = (num) ->
  odd = true
  sum = 0

  digits = (num + '').split('').reverse()

  for digit in digits
    digit = parseInt(digit, 10)
    digit *= 2 if (odd = !odd)
    digit -= 9 if digit > 9
    sum += digit

  sum % 10 == 0

hasTextSelected = (target) ->
  # If some text is selected
  return true if target.selectionStart? and
    target.selectionStart isnt target.selectionEnd

  # If some text is selected in IE
  return true if document?.selection?.createRange?().text

  false

# Private

# Format Card Number

reFormatCardNumber = (e) ->
  setTimeout ->
    target  = e.currentTarget || e.target
    value   = target.value
    value   = payment.formatCardNumber(value)
    target.value = value

formatCardNumber = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.currentTarget || e.target
  value   = target.value
  card    = cardFromNumber(value + digit)
  length  = (value.replace(/\D/g, '') + digit).length

  upperLength = 16
  upperLength = card.length[card.length.length - 1] if card
  return if length >= upperLength

  # Return if focus isn't at the end of the text
  return if target.getAttribute('selectionStart')? and
    target.getAttribute('selectionStart') isnt value.length

  if card && card.type is 'amex'
    # AMEX cards are formatted differently
    re = /^(\d{4}|\d{4}\s\d{6})$/
  else
    re = /(?:^|\s)(\d{4})$/

  # If '4242' + 4
  if re.test(value)
    e.preventDefault()
    setTimeout -> target.value = value + ' ' + digit

  # If '424' + 2
  else if re.test(value + digit)
    e.preventDefault()
    setTimeout -> target.value = value + digit + ' '

formatBackCardNumber = (e) ->
  target = e.currentTarget || e.target
  value  = target.value

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if target.getAttribute('selectionStart')? and
    target.getAttribute('selectionStart') isnt value.length

  # Remove the trailing space
  if /\d\s$/.test(value)
    e.preventDefault()
    setTimeout -> target.value = value.replace(/\d\s$/, '')
  else if /\s\d?$/.test(value)
    e.preventDefault()
    setTimeout -> target.value = value.replace(/\s\d?$/, '')

# Format Expiry

reFormatExpiry = (e) ->
  setTimeout ->
    target = e.currentTarget || e.target
    value  = target.value
    value  = payment.formatExpiry(value)
    target.value = value

formatExpiry = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.currentTarget || e.target
  val    = target.value + digit

  if /^\d$/.test(val) and val not in ['0', '1']
    e.preventDefault()
    setTimeout -> target.value = "0#{val} / "

  else if /^\d\d$/.test(val)
    e.preventDefault()
    setTimeout -> target.value = "#{val} / "

formatForwardExpiry = (e) ->
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.currentTarget || e.target
  val    = target.value

  if /^\d\d$/.test(val)
    target.value = "#{val} / "

formatForwardSlashAndSpace = (e) ->
  which = String.fromCharCode(e.which)
  return unless which is '/' or which is ' '

  target = e.currentTarget || e.target
  val    = target.value

  if /^\d$/.test(val) and val isnt '0'
    target.value = "0#{val} / "

formatBackExpiry = (e) ->
  target = e.currentTarget || e.target
  value  = target.value

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if target.getAttribute('selectionStart')? and
    target.getAttribute('selectionStart') isnt value.length

  # Remove the trailing space
  if /\s\/\s\d?$/.test(value)
    e.preventDefault()
    setTimeout -> target.value = value.replace(/\s\/\s\d?$/, '')

#  Restrictions

restrictNumeric = (e) ->
  # Key event is for a browser shortcut
  return true if e.metaKey or e.ctrlKey

  # If keycode is a space
  return false if e.which is 32

  # If keycode is a special char (WebKit)
  return true if e.which is 0

  # If char is a special char (Firefox)
  return true if e.which < 33

  input = String.fromCharCode(e.which)

  # Char is a number or a space
  !!/[\d\s]/.test(input)

restrictCardNumber = (e) ->
  target = e.currentTarget || e.target
  digit  = String.fromCharCode(e.which)
  return true unless /^\d+$/.test(digit)

  return true if hasTextSelected(target)

  # Restrict number of digits
  value = (target.value + digit).replace(/\D/g, '')
  card  = cardFromNumber(value)

  if card
    value.length <= card.length[card.length.length - 1]
  else
    # All other cards are 16 digits long
    value.length <= 16

restrictExpiry = (e) ->
  target = e.currentTarget || e.target
  digit  = String.fromCharCode(e.which)
  return true unless /^\d+$/.test(digit)

  return true if hasTextSelected(target)

  value = target.value + digit
  value = value.replace(/\D/g, '')

  return !(value.length > 6)

restrictCVC = (e) ->
  target = e.currentTarget || e.target
  digit  = String.fromCharCode(e.which)
  return true unless /^\d+$/.test(digit)

  return true if hasTextSelected(target)

  val = target.value + digit
  val.length <= 4

setCardType = (e) ->
  target   = e.currentTarget || e.target
  val      = target.value
  cardType = payment.cardType(val) or 'unknown'

  unless target.classList.contains(cardType)
    allTypes = (card.type for card in cards)

    target.classList.remove('unknown')
    target.classList.remove(type) for type in allTypes

    target.classList.add(cardType)
    target.classList.toggle('identified', cardType isnt 'unknown')
    event = new CustomEvent 'payment.cardType', cardType
    target.dispatchEvent(event)
    #Check what to return "target.dispatchEvent(event)" or "target"
    target

# Public

# Formatting

payment.fn.formatCardCVC = ->
  payment('restrictNumeric', this)
  onEvent(this, 'keypress', restrictCVC)
  this

payment.fn.formatCardExpiry = ->
  payment('restrictNumeric', this)
  onEvent(this, 'keypress', restrictExpiry)
  @addEventListener('keypress', formatExpiry, false)
  @addEventListener('keypress', formatForwardSlashAndSpace, false)
  @addEventListener('keypress', formatForwardExpiry, false)
  @addEventListener('keydown',  formatBackExpiry, false)
  @addEventListener('change', reFormatExpiry, false)
  @addEventListener('input', reFormatExpiry, false)
  this

payment.fn.formatCardNumber = ->
  payment('restrictNumeric', this)
  onEvent(this, 'keypress', restrictCardNumber)
  @addEventListener('keypress', formatCardNumber, false)
  @addEventListener('keydown', formatBackCardNumber, false)
  @addEventListener('keyup', setCardType, false)
  @addEventListener('paste', reFormatCardNumber, false)
  @addEventListener('change', reFormatCardNumber, false)
  @addEventListener('input', reFormatCardNumber, false)
  @addEventListener('input', setCardType, false)
  this

# Restrictions

payment.fn.restrictNumeric = ->
  onEvent(this, 'keypress', restrictNumeric)
  this

# Validations

payment.fn.cardExpiryVal = ->
  payment.cardExpiryVal(this.value)

payment.cardExpiryVal = (value) ->
  value = value.replace(/\s/g, '')
  [month, year] = value.split('/', 2)

  # Allow for year shortcut
  if year?.length is 2 and /^\d+$/.test(year)
    prefix = (new Date).getFullYear()
    prefix = prefix.toString()[0..1]
    year   = prefix + year

  month = parseInt(month, 10)
  year  = parseInt(year, 10)

  month: month, year: year

payment.validateCardNumber = (num) ->
  num = (num + '').replace(/\s+|-/g, '')
  return false unless /^\d+$/.test(num)

  card = cardFromNumber(num)
  return false unless card

  num.length in card.length and
    (card.luhn is false or luhnCheck(num))

payment.validateCardExpiry = (month, year) ->
  # Allow passing an object
  if typeof month is 'object' and 'month' of month
    {month, year} = month

  return false unless month and year

  month = trim(month)
  year  = trim(year)

  return false unless /^\d+$/.test(month)
  return false unless /^\d+$/.test(year)
  return false unless 1 <= month <= 12

  if year.length == 2
    if year < 70
      year = "20#{year}"
    else
      year = "19#{year}"

  return false unless year.length == 4

  expiry      = new Date(year, month)
  currentTime = new Date

  # Months start from 0 in JavaScript
  expiry.setMonth(expiry.getMonth() - 1)

  # The cc expires at the end of the month,
  # so we need to make the expiry the first day
  # of the month after
  expiry.setMonth(expiry.getMonth() + 1, 1)

  expiry > currentTime

payment.validateCardCVC = (cvc, type) ->
  cvc = trim(cvc)
  return false unless /^\d+$/.test(cvc)

  card = cardFromType(type)
  if card?
    # Check against a explicit card type
    cvc.length in card.cvcLength
  else
    # Check against all types
    cvc.length >= 3 and cvc.length <= 4

payment.cardType = (num) ->
  return null unless num
  cardFromNumber(num)?.type or null

payment.formatCardNumber = (num) ->
  card = cardFromNumber(num)
  return num unless card

  upperLength = card.length[card.length.length - 1]

  num = num.replace(/\D/g, '')
  num = num[0...upperLength]

  if card.format.global
    num.match(card.format)?.join(' ')
  else
    groups = card.format.exec(num)
    return unless groups?
    groups.shift()
    groups = groups.filter(Number) # Filter empty groups
    groups.join(' ')

payment.formatExpiry = (expiry) ->
  parts = expiry.match(/^\D*(\d{1,2})(\D+)?(\d{1,4})?/)
  return '' unless parts

  mon = parts[1] || ''
  sep = parts[2] || ''
  year = parts[3] || ''

  if year.length > 0 || (sep.length > 0 && !(/\ \/?\ ?/.test(sep)))
    sep = ' / '

  if mon.length == 1 and mon not in ['0', '1']
    mon = "0#{mon}"
    sep = ' / '

  return mon + sep + year

window.payment = payment
