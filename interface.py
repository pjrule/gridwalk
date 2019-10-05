from gridwalk import GridChain

state = gerrychain.Partition(...)
chain = GridChain(init_state=state,
            proposal={
                'type': 'flip',
                'constraints': {
                    'population': (98, 102),
                    'cut_edges': 2 * state['cut_edges']
                    # automatically included as updaters
                },
                'pop_col': 'TOTPOP'
            },
            snapshot_interval=10000000,
            snapshot_dir='snapshots',
            stats={
                'seats': {
                    'type': 'election',
                    'format': 'hist',
                    'parties': {
                        'A': 'DEM2008',
                        'B': 'REP2008'
                    }
                },
                'cut_edges': {
                    'type': 'cut_edges',
                    'format': 'summary'
                }
            } # TODO: think about ways to make this better (hist vs. summary)
        )
walk = chain.run()
print(walk[0].stats)  # recovers stats for snapshot 0
print(walk[0].partition)  # returns full GerryChain partition
print(walk.range(0, 100).stats)
print(walk.range(0, 100).partitions)
print(walk.stats)  # alias: walk.range(0, -1).stats
print(walk.partitions)  # alias: walk.range(0, -1).partitions
