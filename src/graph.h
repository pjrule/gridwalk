/**
 * Basic graph structures.
 */
#ifndef _GRAPH_H
#define _GRAPH_H

#include <vector>
#include <string>

namespace gridwalk {
class Graph {
public:
	Graph(std::vector<std::vector<int>> adj,
	      std::vector<double> population);
	void setAttr(std::string name, std::vector<double> vals);
	double population(int nodeId);
	double get(int nodeId, std::string attr);
	std::vector<int> neighbors(int nodeId);
private:
        struct Node {
	    double population;
	    std::vector<double> attrs;
	};
	std::vector<Node> _nodes;
	std::vector<std::string> _attrs;
	std::vector<std::vector<int>> _adj;
};
}
#endif
