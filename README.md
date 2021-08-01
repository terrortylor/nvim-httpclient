# nvim-httpclient

Use nvim as a cURL interface, asynchronously with a results window.

I write a lot of cURL commands, and quite often will have a directory within a project simply for these. These could be to get the state of something, or even to setup the state of a target ready for some testing etc. What I find quite often is that

* I write these in bash
* I end up repeating my self a lot
* I'll re-invent capturing output from one command to use in another
* I end up with many long cURL commands which aren't that readable

Having used tools like postman I was annoyed at leaving the terminal, so thought I'd do something in nvim instead.
This doesn't aim to be feature complete, in terms of cURL, but does cover 99% of my use cases.

I looked around before starting this to see if there was anything else that could be used and save me some time but couldn't find anything that suited my wants.

# Installation

TODO

# Usage example

Create a new file with the filetype `http` and the following contents:

```
https://reqres.in/api/users/2

https://reqres.in
GET /api/users/3
```

Running the command `HttpclientRunFile` will pop up a new window displaying the results for both the calls.

Now, with your cursor somewhere on the first line run the command `HttpclientRunCurrent`. The results window will now refresh to show only the request made.
(You can run this command anywhere in a request block and it will pick up that request, blocks are separated by empty lines.)

As this is just a cURL interface, move your cursor to the line that starts with `GET` and run the command `HttpclientInspectCurrent`, this will show the cURL command it uses in the bottom of your nvim application, further more it places the cURL command onto your clipboard. (This is configurable behaviour.)

HTTP requests are separated with an empty line, meaning a single file can have many HTTP request blocks.


## Headers

Headers are declared in a HTTP block like this:
```
HEADER X-Auth: secr3t
H X-Auth: secr3t

HEADER X-Auth= secr3t
H X-Auth= secr3t
```

## Variables

Variables can be declared to be used in HTTP blocks, these should be defined outside of a HTTP block, are scoped to the buffer, and can be declared out out of order (i.e. all at the bottom of the buffer).

Variables can be declared like this:
```
VAR token: 12345678
V token: 12345678

VAR token= 12345678
V token= 12345678
```

And then used like this:
```
VAR user: 3

https://reqres.in
GET /api/users/@user@
```

When using variables, the `HttpclientInspectCurrent` command will substitute the variables so the cURL is ready to run.

# Configuration

When calling the `setup` command a config table can be passed in to override any values. The following are the defaults:

```lua
{
  -- highlight group to use for message
  progress_running_highlight = "WarningMsg",
  progress_complete_highlight = "WarningMsg",
  -- handlers used to update status and show results
  update_status = view.show_status,
  update_results = view.update_result_buf,
  -- register to use, when inspecting a HTTP block
  -- if nil then does nothing
  register = "+",
  -- enable/disabled keymaps
  enable_keymaps = true,
  -- Run file
  run_file = "<leader>gtf",
  -- run last command
  run_last = "<leader>gtt",
  -- run current http block
  run_current = "<leader>gtn",
  -- inspect current http block
  inspect_current = "<leader>gti",
}
```

# Custom status and result handling

TODO
