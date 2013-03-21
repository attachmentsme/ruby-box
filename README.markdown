ruby-box
--------

Mainted by: [Attachment.me](https://attachments.me)

RubyBox provides a simple, chainable, feature-rich, client for [Box's 2.0 API](http://developers.box.com/docs/).

Authorization
=============

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

```ruby
require 'ruby-box'

session = RubyBox::Session.new({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret',
  access_token: 'access-token'
})

client = RubyBox::Client.new(session)
```

Usage
-----

Once you've created a client, you can start interacting with the Box API. What follows are some basic examples of RubyBox's usage:

Folders
=======

* Listing items in a folder:

```ruby
files = client.folder('/image_folder').files # all files in a folder.
folders = client.root_folder.folders # all folders in the root directory.
files_and_folders = client.folder('files').items # all files and folders in /files
```

* Creating a Folder:

```ruby
client.folder('image_folder').create_subfolder('subfolder')
```

* Setting the description on a folder:

```ruby
folder = client.folder('image_folder')
folder.description = 'Description on Folder'
folder.update
```

* Listing the comments in a discussion surrounding a folder.

```ruby
folder = client.folder('image_folder')
discussion = folder.discussions.first
discussion.comments.each {|comment| p comment.message}
```

Files
=====

Search
======

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

