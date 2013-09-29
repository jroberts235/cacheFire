require 'crack'

def varnishRatio
     cache_hit = 0
    cache_miss = 0
    cache_pass = 0

    raise "Can't find vanishstat!" unless File.exist?('/usr/bin/varnishstat')

    varnishstat = `/usr/bin/varnishstat -x -f cache_hit,cache_miss,cache_pass`
    stats = Crack::XML.parse(varnishstat)

    stats['varnishstat']['stat'].each do |stat|
        cache_hit  = stat['value'] if stat['name'] == 'cache_hit'
        cache_miss = stat['value'] if stat['name'] == 'cache_miss'
    end

    total = cache_hit.to_i + cache_miss.to_i 
    if total == 0
        ratio = 0
        return ratio
    else
        ratio = ((cache_hit.to_f / total.to_f) * 100).to_i
        return ratio
    end
end
