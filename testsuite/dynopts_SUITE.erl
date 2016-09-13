-module(dynopts_SUITE).

-include("testsuite.hrl").

-compile(export_all).

all() ->
    [
     default_dynopts,
     generated_dynopts
    ].

group() ->
    [
    ].

%%====================================================================
init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_Group, Config) ->
    Config.

end_per_group(_Test, _Config) ->
    ok.

init_per_testcase(_Test, Config) ->
    %% Be sure to purge generated module, if any
    code:purge(yaws_dynopts),
    code:delete(yaws_dynopts),
    Config.

end_per_testcase(_Test, _Config) ->
    ok.

%%====================================================================
default_dynopts(_Config) ->
    ?assertNot(yaws_dynopts:is_generated()),
    ?assertEqual(ok, check_ssl_honor_cipher_order()),
    ?assertEqual(ok, check_ssl_client_renegotiation()),
    ?assertEqual(ok, check_ssl_sni()),
    ?assertEqual(ok, check_ssl_log_alert()),
    ?assertEqual(ok, check_erlang_sendfile()),
    ?assertEqual(ok, check_crypto_strong_rand_bytes()),
    ?assertEqual(ok, check_erlang_now()),
    ?assertEqual(ok, check_rand()),
    ok.

generated_dynopts(_Config) ->
    ?assertNot(yaws_dynopts:is_generated()),
    SSLHonorCipherOrder = yaws_dynopts:have_ssl_honor_cipher_order(),
    SSLCliReneg         = yaws_dynopts:have_ssl_client_renegotiation(),
    SSLSni              = yaws_dynopts:have_ssl_sni(),
    SSLLogAlert         = yaws_dynopts:have_ssl_log_alert(),
    ErlSendfile         = yaws_dynopts:have_erlang_sendfile(),
    CryptoRnd           = yaws_dynopts:have_crypto_strong_rand_bytes(),
    ErlNow              = yaws_dynopts:have_erlang_now(),
    Rand                = yaws_dynopts:have_rand(),

    GC = yaws_config:make_default_gconf(false, "dummy_id"),
    ?assertEqual(ok, yaws_dynopts:generate(GC)),

    ?assert(yaws_dynopts:is_generated()),
    ?assertEqual(SSLHonorCipherOrder, yaws_dynopts:have_ssl_honor_cipher_order()),
    ?assertEqual(SSLCliReneg,         yaws_dynopts:have_ssl_client_renegotiation()),
    ?assertEqual(SSLSni,              yaws_dynopts:have_ssl_sni()),
    ?assertEqual(SSLLogAlert,         yaws_dynopts:have_ssl_log_alert()),
    ?assertEqual(ErlSendfile,         yaws_dynopts:have_erlang_sendfile()),
    ?assertEqual(CryptoRnd,           yaws_dynopts:have_crypto_strong_rand_bytes()),
    ?assertEqual(ErlNow,              yaws_dynopts:have_erlang_now()),
    ?assertEqual(Rand,                yaws_dynopts:have_rand()),
    ok.

%%====================================================================
check_ssl_honor_cipher_order() ->
    case yaws_dynopts:have_ssl_honor_cipher_order() of
        true ->
            {ok, Sock} = ssl:listen(8443, [{honor_cipher_order, true}]),
            ok = ssl:close(Sock);
        false ->
            {'EXIT', badarg} =
                (catch ssl:listen(8443, [{honor_cipher_order, true}]))
    end,
    ok.

check_ssl_client_renegotiation() ->
    case yaws_dynopts:have_ssl_client_renegotiation() of
        true ->
            {ok, Sock} = ssl:listen(8443, [{client_renegotiation, true}]),
            ok = ssl:close(Sock);
        false ->
            {'EXIT',badarg} =
                (catch ssl:listen(8443, [{client_renegotiation, true}]))
    end,
    ok.

check_ssl_sni() ->
    case yaws_dynopts:have_ssl_sni() of
        true ->
            {ok, Sock} = ssl:listen(8443, [{sni_fun, fun(_) -> [] end}]),
            ok = ssl:close(Sock);
        false ->
            {'EXIT', badarg} =
                (catch ssl:listen(8443, [{sni_fun, fun(_) -> [] end}]))
    end,
    ok.

check_ssl_log_alert() ->
    case yaws_dynopts:have_ssl_log_alert() of
        true ->
            {ok, Sock} = ssl:listen(8443, [{log_alert, true}]),
            ok = ssl:close(Sock);
        false ->
            {'EXIT', badarg} =
                (catch ssl:listen(8443, [{log_alert, true}]))
    end,
    ok.

check_erlang_sendfile() ->
    Funs = file:module_info(exports),
    case yaws_dynopts:have_erlang_sendfile() of
        true ->
            true = lists:member({sendfile, 5}, Funs),
            true = ($R /= hd(erlang:system_info(otp_release)));
        false ->
            case lists:member({sendfile, 5}, Funs) of
                true  -> true = ($R == hd(erlang:system_info(otp_release)));
                false -> ok
            end
    end,
    ok.

check_crypto_strong_rand_bytes() ->
    Funs = crypto:module_info(exports),
    case yaws_dynopts:have_crypto_strong_rand_bytes() of
        true  -> true  = lists:member({strong_rand_bytes, 1}, Funs);
        false -> false = lists:member({strong_rand_bytes, 1}, Funs)
    end,
    ok.

check_erlang_now() ->
    Funs = erlang:module_info(exports),
    case yaws_dynopts:have_erlang_now() of
        true  -> false = lists:member({unique_integer, 1}, Funs);
        false -> true  = lists:member({unique_integer, 1}, Funs)
    end,
    ok.

check_rand() ->
    case yaws_dynopts:have_rand() of
        true  -> {module, rand} = code:ensure_loaded(rand);
        false -> {error, _}     = code:ensure_loaded(rand)
    end,
    ok.
