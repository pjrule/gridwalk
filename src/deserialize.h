/**
 * Deserialization tools for loading JSON adjacency graphs and run configs.
 */
#ifndef _DESERIALIZE_H
#define _DESERIALIZE_H

#include <istream>
#include "graph.h"
#include "chain.h"

using namespace gridwalk::Graph, gridwalk::Chain;

namespace gridwalk {
class Deserializer {
public:
	static Graph loadGraph(std::istream& graphFile);
	static Chain loadChain(std::istream& configFile, Graph& graph);
private:
	Deserializer() {}  // dummy initializer (static methods only)
}
};
#endif
