# Группирует похожие файлы по кластерам.
# Например f1 похож на f2, f2 похож на f3, f4 похож на f5, f6 похож на f7.
# Тогда будет определено 3 кластера: [f1, f2, f3], [f4, f5], [f6, f7].
class GroupFNames
  # Пример graph:
  # {
  #  'f1' => ['f2', 'f3'],
  #  'f2' => ['f1', 'f4'],
  #  'f3' => ['f1'],
  #  'f4' => ['f2'],
  #  'f5' => ['f6'],
  #  'f6' => ['f5'],
  # }
  # Пример clusters:
  # [
  #  ['f1', 'f2', 'f3', 'f4'],
  #  ['f5', 'f6'],
  # ]
  def clusters(graph)
    visited = {}
    clusters = []

    graph.keys.each do |node|
      unless visited[node]
        clusters << dfs(node, graph, visited, [])
      end
    end

    clusters
  end

  private

  def dfs(node, graph, visited, cluster)
    visited[node] = true
    cluster << node

    graph[node].each do |n|
      dfs(n, graph, visited, cluster) unless visited[n]
    end

    cluster
  end
end
