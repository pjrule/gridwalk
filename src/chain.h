#include "step.h"
#include "graph.h"
#include "proposal.h"
#include <vector>

namespace gridwalk {
class Chain {
public:
	Chain(gridwalk::Graph graph, gridwalk::Proposal proposal);
	gridwalk::Step next();
private:
        gridwalk::Graph graph;
	gridwalk::Proposal proposal;
}
}
