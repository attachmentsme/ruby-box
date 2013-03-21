ruby-box
========

Mainted by Attachment.me

RubyBox provides a simple, chainable, feature-rich, client for [http://developers.box.com/docs/](Box's 2.0 API).

Authorization
-------------

RubyBox uses Box's OAuth2 Implementaton, Here are the steps involved in authorizing a client:

1. Get the authorization url.

```ruby
require 'ruby-box'

session = RubyBox::Session.new({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret'
})

authorize_url = session.authorize_url('https://redirect-url-in-app-settings')
```

2. After redirecting to the authorize_url, exchange the _code_ given for an _access\_token_

```ruby
session.get_access_token('code-returned-to-redirect_url')
```

3. Create a client using a session initialized with the _access\_token_.

```
require 'ruby-box'

session = RubyBox::Session.new({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret',
  access_token: 'access-token'
})

client = RubyBox::Client.new(session)
```

The client is used to make API requests to Box.com.

Usage
-----

Contributors
------------

* Benjamin Coe
* Larry Kang
* Dan Reed
* Jesse Miller

Contributing to ruby-box
-----------------------
 
* Rename account.example to account.yml and fill in your Box credentials
* Type bundle install
* Type rake.. tests should pass
* Add a failing test
* Make it pass
* Submit a pull request

Copyright
---------

Copyright (c) 2012 Attachments.me. See LICENSE.txt for
further details.

