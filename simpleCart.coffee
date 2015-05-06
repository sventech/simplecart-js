###~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~
	Copyright (c) 2012 Brett Wejrowski

	wojodesign.com
	simplecartjs.org
	http://github.com/wojodesign/simplecart-js

	VERSION 3.0.5

	Dual licensed under the MIT or GPL licenses.
~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~
###

### jshint browser: true, unused: true, white: true, nomen: true, regexp: true, maxerr: 50, indent: 4 ###

### jshint laxcomma:true ###

do (window, document) ->

  ###global HTMLElement ###

  typeof_string = typeof ''
  typeof_undefined = typeof undefined
  typeof_function = typeof ->
  typeof_object = typeof {}

  isTypeOf = (item, type) ->
    typeof item == type

  isString = (item) ->
    isTypeOf item, typeof_string

  isUndefined = (item) ->
    isTypeOf item, typeof_undefined

  isFunction = (item) ->
    isTypeOf item, typeof_function

  isObject = (item) ->
    isTypeOf item, typeof_object

  isElement = (o) ->
    if typeof HTMLElement == 'object' then o instanceof HTMLElement else typeof o == 'object' and o.nodeType == 1 and typeof o.nodeName == 'string'

  generateSimpleCart = (space) ->
    # stealing this from selectivizr
    selectorEngines = 
      'MooTools': '$$'
      'Prototype': '$$'
      'jQuery': '*'
    item_id = 0
    item_id_namespace = 'SCI-'
    sc_items = {}
    namespace = space or 'simpleCart'
    selectorFunctions = {}
    eventFunctions = {}
    baseEvents = {}
    localStorage = window.localStorage
    console = window.console or
      msgs: []
      log: (msg) ->
        console.msgs.push msg
        return
    _VALUE_ = 'value'
    _TEXT_ = 'text'
    _HTML_ = 'html'
    _CLICK_ = 'click'
    currencies = 
      'USD':
        code: 'USD'
        symbol: '&#36;'
        name: 'US Dollar'
      'AUD':
        code: 'AUD'
        symbol: '&#36;'
        name: 'Australian Dollar'
      'BRL':
        code: 'BRL'
        symbol: 'R&#36;'
        name: 'Brazilian Real'
      'CAD':
        code: 'CAD'
        symbol: '&#36;'
        name: 'Canadian Dollar'
      'CZK':
        code: 'CZK'
        symbol: '&nbsp;&#75;&#269;'
        name: 'Czech Koruna'
        after: true
      'DKK':
        code: 'DKK'
        symbol: 'DKK&nbsp;'
        name: 'Danish Krone'
      'EUR':
        code: 'EUR'
        symbol: '&euro;'
        name: 'Euro'
      'HKD':
        code: 'HKD'
        symbol: '&#36;'
        name: 'Hong Kong Dollar'
      'HRK':
        code: 'HRK'
        symbol: 'HRK&nbsp;'
        name: 'Croatian kuna'
      'HUF':
        code: 'HUF'
        symbol: '&#70;&#116;'
        name: 'Hungarian Forint'
      'ILS':
        code: 'ILS'
        symbol: '&#8362;'
        name: 'Israeli New Sheqel'
      'JPY':
        code: 'JPY'
        symbol: '&yen;'
        name: 'Japanese Yen'
        accuracy: 0
      'MXN':
        code: 'MXN'
        symbol: '&#36;'
        name: 'Mexican Peso'
      'NOK':
        code: 'NOK'
        symbol: 'NOK&nbsp;'
        name: 'Norwegian Krone'
      'NZD':
        code: 'NZD'
        symbol: '&#36;'
        name: 'New Zealand Dollar'
      'PLN':
        code: 'PLN'
        symbol: 'PLN&nbsp;'
        name: 'Polish Zloty'
      'RUB':
        code: 'RUB'
        symbol: '&#8381;'
        name: 'Russian Ruble'
      'GBP':
        code: 'GBP'
        symbol: '&pound;'
        name: 'Pound Sterling'
      'SGD':
        code: 'SGD'
        symbol: '&#36;'
        name: 'Singapore Dollar'
      'SEK':
        code: 'SEK'
        symbol: 'SEK&nbsp;'
        name: 'Swedish Krona'
      'CHF':
        code: 'CHF'
        symbol: 'CHF&nbsp;'
        name: 'Swiss Franc'
      'THB':
        code: 'THB'
        symbol: '&#3647;'
        name: 'Thai Baht'
      'BTC':
        code: 'BTC'
        symbol: ' BTC'
        name: 'Bitcoin'
        accuracy: 4
        after: true
    settings = 
      checkout:
        type: 'PayPal'
        email: 'you@yours.com'
      currency: 'USD'
      language: 'english-us'
      cartStyle: 'div'
      cartTableClass: 'table'
      cartColumns: [
        {
          attr: 'name'
          label: 'Name'
        }
        {
          attr: 'price'
          label: 'Price'
          view: 'currency'
        }
        {
          view: 'decrement'
          label: false
        }
        {
          attr: 'quantity'
          label: 'Qty'
        }
        {
          view: 'increment'
          label: false
        }
        {
          attr: 'total'
          label: 'SubTotal'
          view: 'currency'
        }
        {
          view: 'remove'
          text: 'Remove'
          label: false
        }
      ]
      excludeFromCheckout: [ 'thumb' ]
      shippingFlatRate: 0
      shippingQuantityRate: 0
      shippingTotalRate: 0
      shippingCustom: null
      taxRate: 0
      taxCountry: false
      taxRegion: false
      taxShipping: false
      data: {}

    simpleCart = (options) ->
      # shortcut for simpleCart.ready
      if isFunction(options)
        return simpleCart.ready(options)
      # set options
      if isObject(options)
        return simpleCart.extend(settings, options)
      return

    $engine = undefined
    cartColumnViews = undefined
    # function for extending objects
    # cart column wrapper class and functions

    cartColumn = (opts) ->
      options = opts or {}
      simpleCart.extend {
        attr: ''
        label: ''
        view: 'attr'
        text: ''
        className: ''
        hide: false
      }, options

    cartCellView = (item, column) ->
      viewFunc = if isFunction(column.view) then column.view else if isString(column.view) and isFunction(cartColumnViews[column.view]) then cartColumnViews[column.view] else cartColumnViews.attr
      viewFunc.call simpleCart, item, column

    # The DOM ready check for Internet Explorer
    # used from jQuery

    doScrollCheck = ->
      if simpleCart.isReady
        return
      try
        # If IE is used, use the trick by Diego Perini
        # http://javascript.nwbox.com/IEContentLoaded/
        document.documentElement.doScroll 'left'
      catch e
        setTimeout doScrollCheck, 1
        return
      # and execute any waiting functions
      simpleCart.init()
      return

    # bind ready event used from jquery

    sc_BindReady = ->
      # Catch cases where $(document).ready() is called after the
      # browser event has already occurred.
      if document.readyState == 'complete'
        # Handle it asynchronously to allow scripts the opportunity to delay ready
        return setTimeout(simpleCart.init, 1)
      # Mozilla, Opera and webkit nightlies currently support this event
      if document.addEventListener
        # Use the handy event callback
        document.addEventListener 'DOMContentLoaded', DOMContentLoaded, false
        # A fallback to window.onload, that will always work
        window.addEventListener 'load', simpleCart.init, false
        # If IE event model is used
      else if document.attachEvent
        # ensure firing before onload,
        # maybe late but safe also for iframes
        document.attachEvent 'onreadystatechange', DOMContentLoaded
        # A fallback to window.onload, that will always work
        window.attachEvent 'onload', simpleCart.init
        # If IE and not a frame
        # continually check to see if the document is ready
        toplevel = false
        try
          toplevel = window.frameElement == null
        catch e
        if document.documentElement.doScroll and toplevel
          doScrollCheck()
      return

    simpleCart.extend = (target, opts) ->
      next = undefined
      if isUndefined(opts)
        opts = target
        target = simpleCart
      for next of opts
        `next = next`
        if Object::hasOwnProperty.call(opts, next)
          target[next] = opts[next]
      target

    # create copy function
    simpleCart.extend copy: (n) ->
      cp = generateSimpleCart(n)
      cp.init()
      cp
    # add in the core functionality
    simpleCart.extend
      isReady: false
      add: (values, opt_quiet) ->
        info = values or {}
        newItem = new (simpleCart.Item)(info)
        addItem = true
        quiet = if opt_quiet == true then opt_quiet else false
        oldItem = undefined
        # trigger before add event
        if !quiet
          addItem = simpleCart.trigger('beforeAdd', [ newItem ])
          if addItem == false
            return false
        # if the new item already exists, increment the value
        oldItem = simpleCart.has(newItem)
        if oldItem
          oldItem.increment newItem.quantity()
          newItem = oldItem
          # otherwise add the item
        else
          sc_items[newItem.id()] = newItem
        # update the cart
        simpleCart.update()
        if !quiet
          # trigger after add event
          simpleCart.trigger 'afterAdd', [
            newItem
            isUndefined(oldItem)
          ]
        # return a reference to the added item
        newItem
      each: (array, callback) ->
        next = undefined
        x = 0
        result = undefined
        cb = undefined
        items = undefined
        if isFunction(array)
          cb = array
          items = sc_items
        else if isFunction(callback)
          cb = callback
          items = array
        else
          return
        for next of items
          `next = next`
          if Object::hasOwnProperty.call(items, next)
            result = cb.call(simpleCart, items[next], x, next)
            if result == false
              return
            x += 1
        return
      find: (id) ->
        items = []
        # return object for id if it exists
        if isObject(sc_items[id])
          return sc_items[id]
        # search through items with the given criteria
        if isObject(id)
          simpleCart.each (item) ->
            match = true
            simpleCart.each id, (val, x, attr) ->
              if isString(val)
                # less than or equal to
                if val.match(/<=.*/)
                  val = parseFloat(val.replace('<=', ''))
                  if !(item.get(attr) and parseFloat(item.get(attr)) <= val)
                    match = false
                  # less than
                else if val.match(/</)
                  val = parseFloat(val.replace('<', ''))
                  if !(item.get(attr) and parseFloat(item.get(attr)) < val)
                    match = false
                  # greater than or equal to
                else if val.match(/>=/)
                  val = parseFloat(val.replace('>=', ''))
                  if !(item.get(attr) and parseFloat(item.get(attr)) >= val)
                    match = false
                  # greater than
                else if val.match(/>/)
                  val = parseFloat(val.replace('>', ''))
                  if !(item.get(attr) and parseFloat(item.get(attr)) > val)
                    match = false
                  # equal to
                else if !(item.get(attr) and item.get(attr) == val)
                  match = false
                # equal to non string
              else if !(item.get(attr) and item.get(attr) == val)
                match = false
              match
            # add the item if it matches
            if match
              items.push item
            return
          return items
        # if no criteria is given we return all items
        if isUndefined(id)
          # use a new array so we don't give a reference to the
          # cart's item array
          simpleCart.each (item) ->
            items.push item
            return
          return items
        # return empty array as default
        items
      items: ->
        @find()
      has: (item) ->
        match = false
        simpleCart.each (testItem) ->
          if testItem.equals(item)
            match = testItem
          return
        match
      empty: ->
        # remove each item individually so we see the remove events
        newItems = {}
        simpleCart.each (item) ->
          # send a param of true to make sure it doesn't
          # update after every removal
          # keep the item if the function returns false,
          # because we know it has been prevented
          # from being removed
          if item.remove(true) == false
            newItems[item.id()] = item
          return
        sc_items = newItems
        simpleCart.update()
        return
      quantity: ->
        quantity = 0
        simpleCart.each (item) ->
          quantity += item.quantity()
          return
        quantity
      total: ->
        total = 0
        simpleCart.each (item) ->
          total += item.total()
          return
        total
      grandTotal: ->
        simpleCart.total() + simpleCart.tax() + simpleCart.shipping()
      update: ->
        simpleCart.save()
        simpleCart.trigger 'update'
        return
      init: ->
        simpleCart.load()
        simpleCart.update()
        simpleCart.ready()
        return
      $: (selector) ->
        new (simpleCart.ELEMENT)(selector)
      $create: (tag) ->
        simpleCart.$ document.createElement(tag)
      setupViewTool: ->
        members = undefined
        member = undefined
        context = window
        engine = undefined
        # Determine the "best fit" selector engine
        for engine of selectorEngines
          `engine = engine`
          if Object::hasOwnProperty.call(selectorEngines, engine) and window[engine]
            members = selectorEngines[engine].replace('*', engine).split('.')
            member = members.shift()
            if member
              context = context[member]
            if typeof context == 'function'
              # set the selector engine and extend the prototype of our
              # element wrapper class
              $engine = context
              simpleCart.extend simpleCart.ELEMENT._, selectorFunctions[engine]
              return
        return
      ids: ->
        ids = []
        simpleCart.each (item) ->
          ids.push item.id()
          return
        ids
      save: ->
        simpleCart.trigger 'beforeSave'
        items = {}
        # save all the items
        simpleCart.each (item) ->
          items[item.id()] = simpleCart.extend(item.fields(), item.options())
          return
        localStorage.setItem namespace + '_items', JSON.stringify(items)
        simpleCart.trigger 'afterSave'
        return
      load: ->
        # empty without the update
        sc_items = {}
        items = localStorage.getItem(namespace + '_items')
        if !items
          return
        # we wrap this in a try statement so we can catch
        # any json parsing errors. no more stick and we
        # have a playing card pluckin the spokes now...
        # soundin like a harley.
        try
          simpleCart.each JSON.parse(items), (item) ->
            simpleCart.add item, true
            return
        catch e
          simpleCart.error 'Error Loading data: ' + e
        simpleCart.trigger 'load'
        return
      ready: (fn) ->
        if isFunction(fn)
          # call function if already ready already
          if simpleCart.isReady
            fn.call simpleCart
            # bind if not ready
          else
            simpleCart.bind 'ready', fn
          # trigger ready event
        else if isUndefined(fn) and !simpleCart.isReady
          simpleCart.trigger 'ready'
          simpleCart.isReady = true
        return
      error: (message) ->
        msg = ''
        if isString(message)
          msg = message
        else if isObject(message) and isString(message.message)
          msg = message.message
        try
          console.log 'simpleCart(js) Error: ' + msg
        catch e
        simpleCart.trigger 'error', [ message ]
        return

    ###******************************************************************
    #	TAX AND SHIPPING
    #*****************************************************************
    ###

    simpleCart.extend
      tax: ->
        if settings.taxRegion and settings.taxRegion != settings.currentRegion
          return parseFloat(0)
        if settings.taxCountry and settings.taxCountry != settings.currentCountry
          return parseFloat(0)
        totalToTax = if settings.taxShipping then simpleCart.total() + simpleCart.shipping() else simpleCart.total()
        cost = simpleCart.taxRate() * totalToTax
        simpleCart.each (item) ->
          if item.get('tax')
            cost += item.get('tax')
          else if item.get('taxRate')
            cost += item.get('taxRate') * item.total()
          return
        parseFloat cost
      taxRate: ->
        settings.taxRate or 0
      taxCountry: ->
        settings.taxCountry or ''
      taxRegion: ->
        settings.taxRegion or ''
      currentCountry: ->
        settings.currentCountry or 'XX'
      currentRegion: ->
        settings.currentRegion or 'Nowheresville'
      setCountry: (countryCode) ->
        settings.currentCountry = countryCode or 'XX'
        @trigger 'update'
        return
      setRegion: (regionName) ->
        settings.currentRegion = regionName or 'Nowheresville'
        @trigger 'update'
        return
      shipping: (opt_custom_function) ->
        # shortcut to extend options with custom shipping
        if isFunction(opt_custom_function)
          simpleCart shippingCustom: opt_custom_function
          return
        cost = settings.shippingQuantityRate * simpleCart.quantity() + settings.shippingTotalRate * simpleCart.total() + settings.shippingFlatRate
        if isFunction(settings.shippingCustom)
          cost += settings.shippingCustom.call(simpleCart)
        simpleCart.each (item) ->
          cost += parseFloat(item.get('shipping') or 0)
          return
        parseFloat cost

    ###******************************************************************
    #	CART VIEWS
    #*****************************************************************
    ###

    # built in cart views for item cells
    cartColumnViews =
      attr: (item, column) ->
        item.get(column.attr) or ''
      currency: (item, column) ->
        simpleCart.toCurrency item.get(column.attr) or 0
      link: (item, column) ->
        '<a href=\'' + item.get(column.attr) + '\'>' + column.text + '</a>'
      decrement: (item, column) ->
        '<a href=\'javascript:;\' class=\'' + namespace + '_decrement\'>' + (column.text or '-') + '</a>'
      increment: (item, column) ->
        '<a href=\'javascript:;\' class=\'' + namespace + '_increment\'>' + (column.text or '+') + '</a>'
      decrement_btn: (item, column) ->
        '<a href=\'javascript:;\' class=\'' + namespace + '_decrement btn\'>' + (column.text or '-') + '</a>'
      increment_btn: (item, column) ->
        '<a href=\'javascript:;\' class=\'' + namespace + '_increment btn\'>' + (column.text or '+') + '</a>'
      image: (item, column) ->
        '<img src=\'' + item.get(column.attr) + '\'/>'
      input: (item, column) ->
        '<input type=\'text\' value=\'' + item.get(column.attr) + '\' class=\'' + namespace + '_input\'/>'
      remove: (item, column) ->
        '<a href=\'javascript:;\' class=\'' + namespace + '_remove\'>' + (column.text or 'X') + '</a>'
    simpleCart.extend
      writeCart: (selector) ->
        TABLE = settings.cartStyle.toLowerCase()
        isTable = TABLE == 'table'
        TR = if isTable then 'tr' else 'div'
        TH = if isTable then 'th' else 'div'
        TD = if isTable then 'td' else 'div'
        TABLE_CLASS = if settings.cartTableClass then settings.cartTableClass else 'table'
        THEAD = if isTable then 'thead' else 'div'
        cart_container = simpleCart.$create(TABLE).addClass(TABLE_CLASS)
        thead_container = simpleCart.$create(THEAD)
        header_container = simpleCart.$create(TR).addClass('headerRow')
        container = simpleCart.$(selector)
        column = undefined
        klass = undefined
        label = undefined
        x = undefined
        xlen = undefined
        container.html(' ').append cart_container
        cart_container.append thead_container
        thead_container.append header_container
        # create header
        x = 0
        xlen = settings.cartColumns.length
        while x < xlen
          column = cartColumn(settings.cartColumns[x])
          klass = 'item-' + (column.attr or column.view or column.label or column.text or 'cell') + ' ' + column.className
          label = column.label or ''
          # append the header cell
          header_container.append simpleCart.$create(TH).addClass(klass).html(label)
          x += 1
        # cycle through the items
        simpleCart.each (item, y) ->
          simpleCart.createCartRow item, y, TR, TD, cart_container
          return
        cart_container
      createCartRow: (item, y, TR, TD, container) ->
        row = simpleCart.$create(TR).addClass('itemRow row-' + y + ' ' + (if y % 2 then 'even' else 'odd')).attr('id', 'cartItem_' + item.id())
        j = undefined
        jlen = undefined
        column = undefined
        klass = undefined
        content = undefined
        cell = undefined
        container.append row
        # cycle through the columns to create each cell for the item
        j = 0
        jlen = settings.cartColumns.length
        while j < jlen
          column = cartColumn(settings.cartColumns[j])
          klass = 'item-' + (column.attr or (if isString(column.view) then column.view else column.label or column.text or 'cell')) + ' ' + column.className
          content = cartCellView(item, column)
          cell = simpleCart.$create(TD).addClass(klass).html(content)
          row.append cell
          j += 1
        row

    ###******************************************************************
    #	CART ITEM CLASS MANAGEMENT
    #*****************************************************************
    ###

    simpleCart.Item = (info) ->
      # we use the data object to track values for the item
      _data = {}
      me = this
      # cycle through given attributes and set them to the data object

      checkQuantityAndPrice = ->
        # check to make sure price is valid
        if isString(_data.price)
          # trying to remove all chars that aren't numbers or '.'
          _data.price = parseFloat(_data.price.replace(simpleCart.currency().decimal, '.').replace(/[^0-9\.]+/ig, ''))
        if isNaN(_data.price)
          _data.price = 0
        if _data.price < 0
          _data.price = 0
        # check to make sure quantity is valid
        if isString(_data.quantity)
          _data.quantity = parseInt(_data.quantity.replace(simpleCart.currency().delimiter, ''), 10)
        if isNaN(_data.quantity)
          _data.quantity = 1
        if _data.quantity <= 0
          me.remove()
        return

      if isObject(info)
        simpleCart.extend _data, info
      # set the item id
      item_id += 1
      _data.id = _data.id or item_id_namespace + item_id
      while !isUndefined(sc_items[_data.id])
        item_id += 1
        _data.id = item_id_namespace + item_id
      # getter and setter methods to access private variables

      me.get = (name, skipPrototypes) ->
        usePrototypes = !skipPrototypes
        if isUndefined(name)
          return name
        # return the value in order of the data object and then the prototype
        if isFunction(_data[name]) then _data[name].call(me) else if !isUndefined(_data[name]) then _data[name] else if isFunction(me[name]) and usePrototypes then me[name].call(me) else if !isUndefined(me[name]) and usePrototypes then me[name] else _data[name]

      me.set = (name, value) ->
        if !isUndefined(name)
          _data[name.toLowerCase()] = value
          if name.toLowerCase() == 'price' or name.toLowerCase() == 'quantity'
            checkQuantityAndPrice()
        me

      me.equals = (item) ->
        for label of _data
          if Object::hasOwnProperty.call(_data, label)
            if label != 'quantity' and label != 'id'
              if item.get(label) != _data[label]
                return false
        true

      me.options = ->
        data = {}
        simpleCart.each _data, (val, x, label) ->
          add = true
          simpleCart.each me.reservedFields(), (field) ->
            if field == label
              add = false
            add
          if add
            data[label] = me.get(label)
          return
        data

      checkQuantityAndPrice()
      return

    simpleCart.Item._ = simpleCart.Item.prototype =
      increment: (amount) ->
        diff = amount or 1
        diff = parseInt(diff, 10)
        @quantity @quantity() + diff
        if @quantity() < 1
          @remove()
          return null
        this
      decrement: (amount) ->
        diff = amount or 1
        @increment -parseInt(diff, 10)
      remove: (skipUpdate) ->
        removeItemBool = simpleCart.trigger('beforeRemove', [ sc_items[@id()] ])
        if removeItemBool == false
          return false
        delete sc_items[@id()]
        if !skipUpdate
          simpleCart.update()
        null
      reservedFields: ->
        [
          'quantity'
          'id'
          'item_number'
          'price'
          'name'
          'shipping'
          'tax'
          'taxRate'
        ]
      fields: ->
        data = {}
        me = this
        simpleCart.each me.reservedFields(), (field) ->
          if me.get(field)
            data[field] = me.get(field)
          return
        data
      quantity: (val) ->
        if isUndefined(val) then parseInt(@get('quantity', true) or 1, 10) else @set('quantity', val)
      price: (val) ->
        if isUndefined(val) then parseFloat(@get('price', true).toString().replace(simpleCart.currency().symbol, '').replace(simpleCart.currency().delimiter, '') or 1) else @set('price', parseFloat(val.toString().replace(simpleCart.currency().symbol, '').replace(simpleCart.currency().delimiter, '')))
      id: ->
        @get 'id', false
      total: ->
        @quantity() * @price()

    ###******************************************************************
    #	CHECKOUT MANAGEMENT
    #*****************************************************************
    ###

    simpleCart.extend
      checkout: ->
        if settings.checkout.type.toLowerCase() == 'custom' and isFunction(settings.checkout.fn)
          settings.checkout.fn.call simpleCart, settings.checkout
        else if isFunction(simpleCart.checkout[settings.checkout.type])
          checkoutData = simpleCart.checkout[settings.checkout.type].call(simpleCart, settings.checkout)
          # if the checkout method returns data, try to send the form
          if checkoutData.data and checkoutData.action and checkoutData.method
            # if no one has any objections, send the checkout form
            if false != simpleCart.trigger('beforeCheckout', [ checkoutData.data ])
              simpleCart.generateAndSendForm checkoutData
        else
          simpleCart.error 'No Valid Checkout Method Specified'
        return
      extendCheckout: (methods) ->
        simpleCart.extend simpleCart.checkout, methods
      generateAndSendForm: (opts) ->
        form = simpleCart.$create('form')
        form.attr 'style', 'display:none;'
        form.attr 'action', opts.action
        form.attr 'method', opts.method
        simpleCart.each opts.data, (val, x, name) ->
          form.append simpleCart.$create('input').attr('type', 'hidden').attr('name', name).val(val)
          return
        simpleCart.$('body').append form
        form.el.submit()
        form.remove()
        return
    simpleCart.extendCheckout
      PayPal: (opts) ->
        # account email is required
        if !opts.email
          return simpleCart.error('No email provided for PayPal checkout')
        # build basic form options
        data = 
          cmd: '_cart'
          upload: '1'
          currency_code: simpleCart.currency().code
          business: opts.email
          rm: if opts.method == 'GET' then '0' else '2'
          tax_cart: (simpleCart.tax() * 1).toFixed(2)
          handling_cart: (simpleCart.shipping() * 1).toFixed(2)
          charset: 'utf-8'
        action = if opts.sandbox then 'https://www.sandbox.paypal.com/cgi-bin/webscr' else 'https://www.paypal.com/cgi-bin/webscr'
        method = if opts.method == 'GET' then 'GET' else 'POST'
        # check for return and success URLs in the options
        if opts.success
          data['return'] = opts.success
        if opts.cancel
          data.cancel_return = opts.cancel
        if opts.notify
          data.notify_url = opts.notify
        # add all the items to the form data
        simpleCart.each (item, x) ->
          counter = x + 1
          item_options = item.options()
          optionCount = 0
          send = undefined
          # basic item data
          data['item_name_' + counter] = item.get('name')
          data['quantity_' + counter] = item.quantity()
          data['amount_' + counter] = (item.price() * 1).toFixed(2)
          data['item_number_' + counter] = item.get('item_number') or counter
          # add the options
          simpleCart.each item_options, (val, k, attr) ->
            # paypal limits us to 10 options
            if k < 10
              # check to see if we need to exclude this from checkout
              send = true
              simpleCart.each settings.excludeFromCheckout, (field_name) ->
                if field_name == attr
                  send = false
                return
              if send
                optionCount += 1
                data['on' + k + '_' + counter] = attr
                data['os' + k + '_' + counter] = val
            return
          # options count
          data['option_index_' + x] = Math.min(10, optionCount)
          return
        # return the data for the checkout form
        {
          action: action
          method: method
          data: data
        }
      GoogleCheckout: (opts) ->
        # account id is required
        if !opts.merchantID
          return simpleCart.error('No merchant id provided for GoogleCheckout')
        # google only accepts USD and GBP
        if simpleCart.currency().code != 'USD' and simpleCart.currency().code != 'GBP'
          return simpleCart.error('Google Checkout only accepts USD and GBP')
        # build basic form options
        data = 
          ship_method_name_1: 'Shipping'
          ship_method_price_1: simpleCart.shipping()
          ship_method_currency_1: simpleCart.currency().code
          _charset_: ''
        action = 'https://checkout.google.com/api/checkout/v2/checkoutForm/Merchant/' + opts.merchantID
        method = if opts.method == 'GET' then 'GET' else 'POST'
        # add items to data
        simpleCart.each (item, x) ->
          counter = x + 1
          options_list = []
          send = undefined
          data['item_name_' + counter] = item.get('name')
          data['item_quantity_' + counter] = item.quantity()
          data['item_price_' + counter] = item.price()
          data['item_currency_ ' + counter] = simpleCart.currency().code
          data['item_tax_rate' + counter] = item.get('taxRate') or simpleCart.taxRate()
          # create array of extra options
          simpleCart.each item.options(), (val, x, attr) ->
            # check to see if we need to exclude this from checkout
            send = true
            simpleCart.each settings.excludeFromCheckout, (field_name) ->
              if field_name == attr
                send = false
              return
            if send
              options_list.push attr + ': ' + val
            return
          # add the options to the description
          data['item_description_' + counter] = options_list.join(', ')
          return
        # return the data for the checkout form
        {
          action: action
          method: method
          data: data
        }
      AmazonPayments: (opts) ->
        # required options
        if !opts.merchant_signature
          return simpleCart.error('No merchant signature provided for Amazon Payments')
        if !opts.merchant_id
          return simpleCart.error('No merchant id provided for Amazon Payments')
        if !opts.aws_access_key_id
          return simpleCart.error('No AWS access key id provided for Amazon Payments')
        # build basic form options
        data = 
          aws_access_key_id: opts.aws_access_key_id
          merchant_signature: opts.merchant_signature
          currency_code: simpleCart.currency().code
          tax_rate: simpleCart.taxRate()
          weight_unit: opts.weight_unit or 'lb'
        action = 'https://payments' + (if opts.sandbox then '-sandbox' else '') + '.amazon.com/checkout/' + opts.merchant_id
        method = if opts.method == 'GET' then 'GET' else 'POST'
        # add items to data
        simpleCart.each (item, x) ->
          counter = x + 1
          options_list = []
          data['item_title_' + counter] = item.get('name')
          data['item_quantity_' + counter] = item.quantity()
          data['item_price_' + counter] = item.price()
          data['item_sku_ ' + counter] = item.get('sku') or item.id()
          data['item_merchant_id_' + counter] = opts.merchant_id
          if item.get('weight')
            data['item_weight_' + counter] = item.get('weight')
          if settings.shippingQuantityRate
            data['shipping_method_price_per_unit_rate_' + counter] = settings.shippingQuantityRate
          # create array of extra options
          simpleCart.each item.options(), (val, x, attr) ->
            # check to see if we need to exclude this from checkout
            send = true
            simpleCart.each settings.excludeFromCheckout, (field_name) ->
              if field_name == attr
                send = false
              return
            if send and attr != 'weight' and attr != 'tax'
              options_list.push attr + ': ' + val
            return
          # add the options to the description
          data['item_description_' + counter] = options_list.join(', ')
          return
        # return the data for the checkout form
        {
          action: action
          method: method
          data: data
        }
      SendForm: (opts) ->
        # url required
        if !opts.url
          return simpleCart.error('URL required for SendForm Checkout')
        # build basic form options
        data = 
          currency: simpleCart.currency().code
          shipping: simpleCart.shipping()
          tax: simpleCart.tax()
          taxRate: simpleCart.taxRate()
          taxCountry: simpleCart.taxCountry()
          taxRegion: simpleCart.taxRegion()
          itemCount: simpleCart.find({}).length
        action = opts.url
        method = if opts.method == 'GET' then 'GET' else 'POST'
        # add items to data
        simpleCart.each (item, x) ->
          counter = x + 1
          options_list = []
          send = undefined
          data['item_name_' + counter] = item.get('name')
          data['item_quantity_' + counter] = item.quantity()
          data['item_price_' + counter] = item.price()
          # create array of extra options
          simpleCart.each item.options(), (val, x, attr) ->
            # check to see if we need to exclude this from checkout
            send = true
            simpleCart.each settings.excludeFromCheckout, (field_name) ->
              if field_name == attr
                send = false
              return
            if send
              options_list.push attr + ': ' + val
            return
          # add the options to the description
          data['item_options_' + counter] = options_list.join(', ')
          return
        # check for return and success URLs in the options
        if opts.success
          data['return'] = opts.success
        if opts.cancel
          data.cancel_return = opts.cancel
        if opts.extra_data
          data = simpleCart.extend(data, opts.extra_data)
        # return the data for the checkout form
        {
          action: action
          method: method
          data: data
        }

    ###******************************************************************
    #	EVENT MANAGEMENT
    #*****************************************************************
    ###

    eventFunctions =
      bind: (name, callback) ->
        if !isFunction(callback)
          return this
        if !@_events
          @_events = {}
        # split by spaces to allow for multiple event bindings at once
        eventNameList = name.split(RegExp(' +'))
        # iterate through and bind each event
        simpleCart.each eventNameList, (eventName) ->
          if @_events[eventName] == true
            callback.apply this
          else if !isUndefined(@_events[eventName])
            @_events[eventName].push callback
          else
            @_events[eventName] = [ callback ]
          return
        this
      trigger: (name, options) ->
        returnval = true
        x = undefined
        xlen = undefined
        if !@_events
          @_events = {}
        if !isUndefined(@_events[name]) and isFunction(@_events[name][0])
          x = 0
          xlen = @_events[name].length
          while x < xlen
            returnval = @_events[name][x].apply(this, options or [])
            x += 1
        if returnval == false
          return false
        true
    # alias for bind
    eventFunctions.on = eventFunctions.bind
    simpleCart.extend eventFunctions
    simpleCart.extend simpleCart.Item._, eventFunctions
    # base simpleCart events in options
    baseEvents =
      beforeAdd: null
      afterAdd: null
      load: null
      beforeSave: null
      afterSave: null
      update: null
      ready: null
      checkoutSuccess: null
      checkoutFail: null
      beforeCheckout: null
      beforeRemove: null
    # extend with base events
    simpleCart baseEvents
    # bind settings to events
    simpleCart.each baseEvents, (val, x, name) ->
      simpleCart.bind name, ->
        if isFunction(settings[name])
          settings[name].apply this, arguments
        return
      return

    ###******************************************************************
    #	FORMATTING FUNCTIONS
    #*****************************************************************
    ###

    simpleCart.extend
      toCurrency: (number, opts) ->
        num = parseFloat(number)
        opt_input = opts or {}
        _opts = simpleCart.extend(simpleCart.extend({
          symbol: '$'
          decimal: '.'
          delimiter: ','
          accuracy: 2
          after: false
        }, simpleCart.currency()), opt_input)
        numParts = num.toFixed(_opts.accuracy).split('.')
        dec = numParts[1]
        ints = numParts[0]
        ints = simpleCart.chunk(ints.reverse(), 3).join(_opts.delimiter.reverse()).reverse()
        (if !_opts.after then _opts.symbol else '') + ints + (if dec then _opts.decimal + dec else '') + (if _opts.after then _opts.symbol else '')
      chunk: (str, n) ->
        if typeof n == 'undefined'
          n = 2
        result = str.match(new RegExp('.{1,' + n + '}', 'g'))
        result or []
    # reverse string function

    String::reverse = ->
      @split('').reverse().join ''

    # currency functions
    simpleCart.extend currency: (currency) ->
      if isString(currency) and !isUndefined(currencies[currency])
        settings.currency = currency
      else if isObject(currency)
        currencies[currency.code] = currency
        settings.currency = currency.code
      else
        return currencies[settings.currency]
      return

    ###******************************************************************
    #	VIEW MANAGEMENT
    #*****************************************************************
    ###

    simpleCart.extend
      bindOutlets: (outlets) ->
        simpleCart.each outlets, (callback, x, selector) ->
          simpleCart.bind 'update', ->
            simpleCart.setOutlet '.' + namespace + '_' + selector, callback
            return
          return
        return
      setOutlet: (selector, func) ->
        val = func.call(simpleCart, selector)
        if isObject(val) and val.el
          simpleCart.$(selector).html(' ').append val
        else if !isUndefined(val)
          simpleCart.$(selector).html val
        return
      bindInputs: (inputs) ->
        simpleCart.each inputs, (info) ->
          simpleCart.setInput '.' + namespace + '_' + info.selector, info.event, info.callback
          return
        return
      setInput: (selector, event, func) ->
        simpleCart.$(selector).live event, func
        return
    # class for wrapping DOM selector shit

    simpleCart.ELEMENT = (selector) ->
      @create selector
      @selector = selector or null
      # "#" + this.attr('id'); TODO: test length?
      return

    simpleCart.extend selectorFunctions,
      'MooTools':
        text: (text) ->
          @attr _TEXT_, text
        html: (html) ->
          @attr _HTML_, html
        val: (val) ->
          @attr _VALUE_, val
        attr: (attr, val) ->
          if isUndefined(val)
            return @el[0] and @el[0].get(attr)
          @el.set attr, val
          this
        remove: ->
          @el.dispose()
          null
        addClass: (klass) ->
          @el.addClass klass
          this
        removeClass: (klass) ->
          @el.removeClass klass
          this
        append: (item) ->
          @el.adopt item.el
          this
        each: (callback) ->
          if isFunction(callback)
            simpleCart.each @el, (e, i, c) ->
              callback.call i, i, e, c
              return
          this
        click: (callback) ->
          if isFunction(callback)
            @each (e) ->
              e.addEvent _CLICK_, (ev) ->
                callback.call e, ev
                return
              return
          else if isUndefined(callback)
            @el.fireEvent _CLICK_
          this
        live: (event, callback) ->
          selector = @selector
          if isFunction(callback)
            simpleCart.$('body').el.addEvent event + ':relay(' + selector + ')', (e, el) ->
              callback.call el, e
              return
          return
        match: (selector) ->
          @el.match selector
        parent: ->
          simpleCart.$ @el.getParent()
        find: (selector) ->
          simpleCart.$ @el.getElements(selector)
        closest: (selector) ->
          simpleCart.$ @el.getParent(selector)
        descendants: ->
          @find '*'
        tag: ->
          @el[0].tagName
        submit: ->
          @el[0].submit()
          this
        create: (selector) ->
          @el = $engine(selector)
          return
      'Prototype':
        text: (text) ->
          if isUndefined(text)
            return @el[0].innerHTML
          @each (i, e) ->
            $(e).update text
            return
          this
        html: (html) ->
          @text html
        val: (val) ->
          @attr _VALUE_, val
        attr: (attr, val) ->
          if isUndefined(val)
            return @el[0].readAttribute(attr)
          @each (i, e) ->
            $(e).writeAttribute attr, val
            return
          this
        append: (item) ->
          @each (i, e) ->
            if item.el
              item.each (i2, e2) ->
                $(e).appendChild e2
                return
            else if isElement(item)
              $(e).appendChild item
            return
          this
        remove: ->
          @each (i, e) ->
            $(e).remove()
            return
          this
        addClass: (klass) ->
          @each (i, e) ->
            $(e).addClassName klass
            return
          this
        removeClass: (klass) ->
          @each (i, e) ->
            $(e).removeClassName klass
            return
          this
        each: (callback) ->
          if isFunction(callback)
            simpleCart.each @el, (e, i, c) ->
              callback.call i, i, e, c
              return
          this
        click: (callback) ->
          if isFunction(callback)
            @each (i, e) ->
              $(e).observe _CLICK_, (ev) ->
                callback.call e, ev
                return
              return
          else if isUndefined(callback)
            @each (i, e) ->
              $(e).fire _CLICK_
              return
          this
        live: (event, callback) ->
          if isFunction(callback)
            selector = @selector
            document.observe event, (e, el) ->
              if el == $engine(e).findElement(selector)
                callback.call el, e
              return
          return
        parent: ->
          simpleCart.$ @el.up()
        find: (selector) ->
          simpleCart.$ @el.getElementsBySelector(selector)
        closest: (selector) ->
          simpleCart.$ @el.up(selector)
        descendants: ->
          simpleCart.$ @el.descendants()
        tag: ->
          @el.tagName
        submit: ->
          @el[0].submit()
          return
        create: (selector) ->
          if isString(selector)
            @el = $engine(selector)
          else if isElement(selector)
            @el = [ selector ]
          return
      'jQuery':
        passthrough: (action, val) ->
          if isUndefined(val)
            return @el[action]()
          @el[action] val
          this
        text: (text) ->
          @passthrough _TEXT_, text
        html: (html) ->
          @passthrough _HTML_, html
        val: (val) ->
          @passthrough 'val', val
        append: (item) ->
          target = item.el or item
          @el.append target
          this
        attr: (attr, val) ->
          if isUndefined(val)
            return @el.attr(attr)
          @el.attr attr, val
          this
        remove: ->
          @el.remove()
          this
        addClass: (klass) ->
          @el.addClass klass
          this
        removeClass: (klass) ->
          @el.removeClass klass
          this
        each: (callback) ->
          @passthrough 'each', callback
        click: (callback) ->
          @passthrough _CLICK_, callback
        live: (event, callback) ->
          $engine(document).delegate @selector, event, callback
          this
        parent: ->
          simpleCart.$ @el.parent()
        find: (selector) ->
          simpleCart.$ @el.find(selector)
        closest: (selector) ->
          simpleCart.$ @el.closest(selector)
        tag: ->
          @el[0].tagName
        descendants: ->
          simpleCart.$ @el.find('*')
        submit: ->
          @el.submit()
        create: (selector) ->
          @el = $engine(selector)
          return
    simpleCart.ELEMENT._ = simpleCart.ELEMENT.prototype
    # bind the DOM setup to the ready event
    simpleCart.ready simpleCart.setupViewTool
    # bind the input and output events
    simpleCart.ready ->
      simpleCart.bindOutlets
        total: ->
          simpleCart.toCurrency simpleCart.total()
        quantity: ->
          simpleCart.quantity()
        items: (selector) ->
          simpleCart.writeCart selector
          return
        tax: ->
          simpleCart.toCurrency simpleCart.tax()
        taxRate: ->
          simpleCart.taxRate().toFixed()
        taxCountry: ->
          simpleCart.taxCountry()
        taxRegion: ->
          simpleCart.taxRegion()
        shipping: ->
          simpleCart.toCurrency simpleCart.shipping()
        grandTotal: ->
          simpleCart.toCurrency simpleCart.grandTotal()
      simpleCart.bindInputs [
        {
          selector: 'checkout'
          event: 'click'
          callback: ->
            simpleCart.checkout()
            return

        }
        {
          selector: 'empty'
          event: 'click'
          callback: ->
            simpleCart.empty()
            return

        }
        {
          selector: 'increment'
          event: 'click'
          callback: ->
            simpleCart.find(simpleCart.$(this).closest('.itemRow').attr('id').split('_')[1]).increment()
            simpleCart.update()
            return

        }
        {
          selector: 'decrement'
          event: 'click'
          callback: ->
            simpleCart.find(simpleCart.$(this).closest('.itemRow').attr('id').split('_')[1]).decrement()
            simpleCart.update()
            return

        }
        {
          selector: 'remove'
          event: 'click'
          callback: ->
            simpleCart.find(simpleCart.$(this).closest('.itemRow').attr('id').split('_')[1]).remove()
            return

        }
        {
          selector: 'input'
          event: 'change'
          callback: ->
            $input = simpleCart.$(this)
            $parent = $input.parent()
            classList = $parent.attr('class').split(' ')
            simpleCart.each classList, (klass) ->
              if klass.match(/item-.+/i)
                field = klass.split('-')[1]
                simpleCart.find($parent.closest('.itemRow').attr('id').split('_')[1]).set field, $input.val()
                simpleCart.update()
                return
              return
            return

        }
        {
          selector: 'shelfItem .item_add'
          event: 'click'
          callback: ->
            $button = simpleCart.$(this)
            fields = {}
            $button.closest('.' + namespace + '_shelfItem').descendants().each (x, item) ->
              $item = simpleCart.$(item)
              # check to see if the class matches the item_[fieldname] pattern
              if $item.attr('class') and $item.attr('class').match(/item_.+/) and !$item.attr('class').match(/item_add/)
                # find the class name
                simpleCart.each $item.attr('class').split(' '), (klass) ->
                  attr = undefined
                  val = undefined
                  type = undefined
                  # get the value or text depending on the tagName
                  if klass.match(/item_.+/)
                    attr = klass.split('_')[1]
                    val = ''
                    switch $item.tag().toLowerCase()
                      when 'input', 'textarea', 'select'
                        type = $item.attr('type')
                        if !type or (type.toLowerCase() == 'checkbox' or type.toLowerCase() == 'radio') and $item.attr('checked') or type.toLowerCase() == 'text' or type.toLowerCase() == 'number'
                          val = $item.val()
                      when 'img'
                        val = $item.attr('src')
                      else
                        val = $item.text()
                        break
                    if val != null and val != ''
                      fields[attr.toLowerCase()] = if fields[attr.toLowerCase()] then fields[attr.toLowerCase()] + ', ' + val else val
                  return
              return
            # add the item
            simpleCart.add fields
            return

        }
      ]
      return

    ###******************************************************************
    #	DOM READY
    #*****************************************************************
    ###

    # Cleanup functions for the document ready method
    # used from jQuery

    ###global DOMContentLoaded ###

    if document.addEventListener

      window.DOMContentLoaded = ->
        document.removeEventListener 'DOMContentLoaded', DOMContentLoaded, false
        simpleCart.init()
        return

    else if document.attachEvent

      window.DOMContentLoaded = ->
        # Make sure body exists, at least, in case IE gets a little overzealous (ticket #5443).
        if document.readyState == 'complete'
          document.detachEvent 'onreadystatechange', DOMContentLoaded
          simpleCart.init()
        return

    # bind the ready event
    sc_BindReady()
    simpleCart

  window.simpleCart = generateSimpleCart()
  return
# originally, localStorage and JSON code was here

