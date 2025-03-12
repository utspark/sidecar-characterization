import random

body_length = [ 34000 ] #[100, 1000, 4000, 8000, 32000, 64000] 

for i in body_length:
    body = str(random.getrandbits(4 * i))[0:i]
    
    with open(f'lua_body_{i}.lua', 'w') as file:
        file.write("wrk.headers[\"count\"] = \"1\"\n")
        file.write(f"wrk.headers[\"body_len\"] = \"{i}\"\n")
        file.write(f"wrk.body = \"{body}\"\n")

    