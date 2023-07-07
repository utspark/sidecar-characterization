-- http inspection filter for fault injection based on headers 
wrk.headers["x-envoy-fault-abort-request"] = "404"
