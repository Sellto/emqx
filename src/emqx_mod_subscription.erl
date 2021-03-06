%% Copyright (c) 2018 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_mod_subscription).

-behaviour(emqx_gen_mod).

-include_lib("emqx.hrl").
-include_lib("emqx_mqtt.hrl").

-export([load/1, on_session_created/3, unload/1]).

%%--------------------------------------------------------------------
%% Load/Unload Hook
%%--------------------------------------------------------------------

load(Topics) ->
    emqx_hooks:add('session.created', fun ?MODULE:on_session_created/3, [Topics]).

on_session_created(#{client_id := ClientId}, SessAttrs, Topics) ->
    Username = proplists:get_value(username, SessAttrs),
    Replace = fun(Topic) ->
                      rep(<<"%u">>, Username, rep(<<"%c">>, ClientId, Topic))
              end,
    emqx_session:subscribe(self(), [{Replace(Topic), #{qos => QoS}} || {Topic, QoS} <- Topics]).

unload(_) ->
    emqx_hooks:del('session.created', fun ?MODULE:on_session_created/3).

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------

rep(<<"%c">>, ClientId, Topic) ->
    emqx_topic:feed_var(<<"%c">>, ClientId, Topic);
rep(<<"%u">>, undefined, Topic) ->
    Topic;
rep(<<"%u">>, Username, Topic) ->
    emqx_topic:feed_var(<<"%u">>, Username, Topic).

