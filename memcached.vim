"=============================================================================
" File: memcached.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 25-Aug-2009.
" Version: 0.1
" WebPage: http://github.com/mattn/memcached-vim/tree/master
" Usage:
"
"   :MemcachedServerStart
"     start memcached server
"
"   :MemcachedServerShutdown
"     shutdown memcached server
"
"   :let client = MemcachedClient('VIM2')
"
"   :call client.set('foo', 'bar')
"   :echo client.get('foo')
"   => bar
"
"   :call client.set('foo', {'bar': 'baz'})
"   :echo client.get('foo')['bar']
"   => baz
"
"   :echo MemcachedServerList()
"   VIM
"   VIM1

if &cp || (exists('g:loaded_memcacehd_vim') && g:loaded_memcacehd_vim)
  finish
endif
let g:loaded_memcacehd_vim = 1

let s:client = {}

function! s:client.get(key)
  if type(self._servers) != type([])
    let servers = [self._servers]
  else
    let servers = self._servers
  endif
  for server in servers
    try
      return eval(remote_expr(server, 'string(memcached.get(' . string(a:key) . '))'))
    catch /^Vim\%((\a\+)\)\=:E/
    endtry
  endfor
  throw "failed to get()"
endfunction

function! s:client.set(key, val)
  if type(self._servers) != type([])
    let servers = [self._servers]
  else
    let servers = self._servers
  endif
  for server in servers
    try
      call remote_expr(server, 'memcached.set(' . string(a:key) . ',' . string(a:val) . ')')
      return
    catch /^Vim\%((\a\+)\)\=:E/
    endtry
  endfor
  throw "failed to set()"
endfunction

function! MemcachedClient(servers)
  let obj = copy(s:client)
  let obj._servers = a:servers
  return obj
endfunction

let s:server = {"data" : {}}

function! s:server.get(key)
  return self.data[a:key]
endfunction

function! s:server.set(key, val)
  let self.data[a:key] = a:val
endfunction

function! s:MemcachedServer()
  return copy(s:server)
endfunction

function! MemcachedServerList()
  let servers = []
  for server in split(serverlist(), "\n")
    if server != v:servername && remote_expr(server, 'exists("g:memcached")')
      call add(servers, server)
    endif
  endfor
  return servers
endfunction

command! MemcachedServerStart :let g:memcached = s:MemcachedServer()
command! MemcachedServerShutdown :silent! unlet g:memcached
