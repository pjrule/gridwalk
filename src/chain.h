#include "step.h"
#include "graph.h"
#include "proposal.h"
#include <vector>

namespace gridwalk {
class Chain {
public:
	Chain(Graph graph, Proposal proposal);
private:
        Graph graph;
	Proposal proposal;
}
}
