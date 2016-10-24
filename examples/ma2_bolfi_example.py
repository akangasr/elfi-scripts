import sys
import time
import numpy as np

from elfi.core import *
from elfi.distributions import *
from elfi.examples.ma2 import *
from elfi.methods import *
from distributed import Client
from functools import partial


def main():
    print("Starting: %s" % (sys.argv), file=sys.stderr)

    loc = "127.0.0.1:%d" % int(sys.argv[1])
    print("Connecting to scheduler at %s" % (loc), file=sys.stderr)
    client = Client(loc)
    print("Connected", file=sys.stderr)

    n = 1000
    t1 = 0.6
    t2 = 0.2

    latents = np.random.randn(n+2)
    y = MA2(n, 1, t1, t2, latents=latents)

    simulator = partial(MA2, n)

    ac1 = partial(autocov, 1)
    ac2 = partial(autocov, 2)

    t1 = Prior('t1', 'uniform', 0, 1)
    Y = Simulator('MA2', simulator, t1, t2, observed=y)
    S1 = Summary('S1', ac1, Y)
    S2 = Summary('S2', ac2, Y)
    d = Discrepancy('d', distance, S1, S2)
    n_sim = 20
    n_batch = 4

    print("Bolfi")
    bolfi = BOLFI(10, d, [t1], batch_size=n_batch, n_surrogate_samples=n_sim, client=client)
    post = bolfi.infer()

    print("\nBolfi (async)")
    async_bolfi = BOLFI(10, d, [t1], sync=False, batch_size=n_batch, n_surrogate_samples=n_sim, client=client)
    async_post = async_bolfi.infer()


if __name__ == "__main__":
    main()
