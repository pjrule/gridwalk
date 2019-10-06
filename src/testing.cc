#include "deserialize.h"
#include "graph.h"
#include "chain.h"
#include <memory>
#include <iostream>

using namespace gridwalk;

int main(int argc, char* argv[]) {
	if(argc == 3) {
		Graph graph;
		Chain chain;
		std::ifstream graphFile(argv[1]);
		std::ifstream configFile(argv[2]);
		if(!graphFile.is_open()) {
			std::cerr << "Cannot open graph file." << std::endl;
			return 1;
		} else {
			graph = Deserializer::loadGraph(graphFile);
		}
		if(!configFile.is_open()) {
			std::cerr << "Cannot open config file." << std::endl;
			return 1;
		} else  {
			chain = Deserializer::loadChain(configFile, graph);
		}
		// TODO: chain.run()
	} else {
		std::cerr << "Usage: gridwalk [GRAPH] [CONFIG]";
		std::cerr << std::endl;
	}
}

