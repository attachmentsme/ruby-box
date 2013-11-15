ruby-box
========

Mainted by: [Attachments.me](https://attachments.me)

RubyBox provides a simple, chainable, feature-rich client for [Box's 2.0 API](http://developers.box.com/docs/).

Authorization
-------------

RubyBox uses Box's OAuth2 Implementaton, Here are the steps involved in authorizing a client:

__1)__ Get the authorization url.

```ruby
require 'ruby-box'

session = RubyBox::Session.new({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret'
})

authorize_url = session.authorize_url('https://redirect-url-in-app-settings')
```

__2)__ After redirecting to the authorize_url, exchange the _code_ given for an _access\_token_

```ruby
@token = session.get_access_token('code-returned-to-redirect_url')
p '@token.token' # the access token.
p '@token.refresh_token' # token that can be exchanged for a new access_token once the access_token expires.

# refreshing token.

session = RubyBox::Session.new({
  client_id: 'your-client-id',
  client_secret: 'your-client-secret',
  access_token: 'original-access-token' 
})

@token = session.refresh_token('your-refresh-token')
```

__3)__ Create a client using a session initialized with the _access\_token_.

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
=====

Once you've created a client, you can start interacting with the Box API. What follows are some basic examples of RubyBox's usage:

Folders
-------

* Listing items in a folder:

```ruby
files = client.folder('/image_folder').files # all files in a folder.
folders = client.root_folder.folders # all folders in the root directory.
files_and_folders = client.folder('files').items # all files and folders in /files
```

* Creating a folder:

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

* Creating a shared link for a folder.

```ruby
folder = client.folder('image_folder').create_shared_link
p folder.shared_link.url # https://www.box.com/s/d6de3224958c1755412
```

Files
-----

* Fetching a file's meta information.

```ruby
file = client.file('/image_folder/an-image.jpg')
p file.name
p file.created_at
```

* Uploading a file to a folder.

```ruby
file = client.upload_file('./LICENSE.txt', '/license_folder')
```

* Downloading a file.

```ruby
f = open('./LOCAL.txt', 'w+')
f.write( client.file('/license_folder/LICENSE.txt').download )
f.close()
```

* Deleting a file.

```ruby
client.file('/license_folder/LICENSE.txt').delete
```

* Displaying comments on a file.

```ruby
comments = client.file('/image_folder/an-image.jpg').comments
comments.each do |comment|
    p comment.message
end
```

* Creating a shared link for a file.

```ruby
file = client.file('/image_folder/an-image.jpg').create_shared_link
p file.shared_link.url # https://www.box.com/s/d6de3224958c1755412
```

* Copying a file to another folder.

```ruby
file = client.file('/image_folder/an-image.jpg')
folder = client.folder('image_folder')
file.copy_to(folder)
```

* Moving a file to another folder.

```ruby
file = client.file('/image_folder/an-image.jpg')
folder = client.folder('image_folder')
file.move_to(folder)
```

* Adding a comment to a file.

```ruby
file = client.file('/image_folder/an-image.jpg')
comment = file.create_comment('Hello World!')
```

Search
------

You can use RubyBox's search method to return files and folders that match a given query.

```ruby
items = client.search('image')
items.each do |item|
    p "type=#{item.type} name=#{item.name}"
end
```

Events
------

You can use RubyBox's event_response method to return an EventResponse that can be used to process any incoming events.

```ruby
eresp = client.event_response
eresp.chunk_size
eresp.next_stream_position
eresp.events.each do |ev|
  p "type=#{ev.event_id} type=#{ev.event_type} user=#{ev.created_by.name}"
end
```

Users
------

Current User Info

```ruby
me = client.me
```

Current User's enterprise

```ruby
me = client.me.enterprise
```

An array of Ruby:Box users in an enterprise (Supports Filtering, Limit and Offset)

```ruby
users = client.users
```

* Remeber the API filters "name" and "login" by the start of the string.  ie: to get "sean+awesome@gmail.com" an approriate filter term would be "sean"

```ruby
users = client.users("sean" , 10 , 1)
```

Contributors
============

* [full list of contributors](https://github.com/attachmentsme/ruby-box/graphs/contributors)

Contributing to ruby-box
========================

RubyBox does not yet support all of Box's API Version 2.0 functionality, be liberal with your contributions.
 
* Rename account.example to account.yml and fill in your Box credentials
* Type bundle install
* Type rake.. tests should pass
* Add a failing test
* Make it pass
* Submit a pull request

Copyright
=========

Copyright (c) 2012 Attachments.me. See LICENSE.txt for
further details.
