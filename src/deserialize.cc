/**
 * Deserialization tools for loading JSON adjacency graphs and run configs.
 */
#include <istream>
#include <nlohmann/json.hpp>
#include "deserialize.h"
#include "graph.h"
#include "chain.h"

using json = nlohmann::json;

namespace gridwalk {
/**
 * @brief 
 *
 * @param configFile
 * @param graph
 *
 * @return 
 */
Chain Deserializer::loadGraph(std::istream& configFile, Graph& graph) {

}
}
