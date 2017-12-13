#Crawler model, for the module, should work

using Requests
using HTTP
using Gumbo
using AbstractTrees
using ArgParse
using JLD

#define our crawler

type Crawler
    startUrl::AbstractString
    urlsVisited::Array{AbstractString}
    urlsToCrawl::Array{AbstractString}
    content::Dict{AbstractString, AbstractString}
    #the content is dictoianry{url: html content}
    breadthFirst::Bool
    
    #constructors
    function Crawler(starturl::AbstractString)
        return new(starturl, AbstractString[], AbstractString[],Dict{AbstractString, AbstractString}(), true)
    end
    function Crawler(starturl::AbstractString, breadthfirst::Bool)
        return new(starturl, AbstractString[],AbstractString[],Dict{AbstractString, AbstractString}(), breadthfirst)
    end
    function Crawler(starturl::AbstractString, urlstocrawl::Array{AbstractString},breadthfirst::Bool)
        return new(starturl, AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), breadthfirst) 
    end
    function Crawler(starturl::AbstractString, urlstocrawl::Array{AbstractString})
        return new(starturl, AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), true)
    end
    #remove this, just a test
    function Crawler(urlstocrawl::Array{AbstractString}, breadthfirst::Bool)
        return new("", AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), breadthfirst)
    end
    function Crawler(urlstocrawl::Array{AbstractString})
        return new("", AbstractString[], urlstocrawl, Dict{AbstractString, AbstractString}(), true)
    end
    
end




function crawl(crawler::Crawler, num_iterations::Integer=10, verbose=true, save=true)
    #first we check if it's the first thing we see. so we should just check this
    #shall we just define variables from the crawler? nah, let's not. we should just access them consistently
    #as it's meant t be updated in place, I assume
    #we should dump this in thefucntoin so it doesn't slow down
    const successCode = 200
    
    #our immediate return if correct
    if isempty(crawler.urlsToCrawl) && crawler.startUrl==""
        return crawler.content, crawler.urlsVisited
    end
    

    if isempty(crawler.urlsToCrawl) && crawler.startUrl!=""
        #so we are at the beginning so we visit our first piece
        #we set the starturl to urls to crawl
        push!(crawler.urlsToCrawl,crawler.startUrl)
        crawler.startUrl=""
    end
    
    #okay, now we begin the loop
    for i in 0:num_iterations
        #we check if empty we probably shouldn't do this on each iteratino, but oh well!
        if isempty(crawler.urlsToCrawl) && crawler.startUrl==""
            return crawler.content, crawler.urlsVisited
        end
        url = pop!(crawler.urlsToCrawl)
        #we get the content
        #we make the request with http
        #we first check this works... idk
        #println(crawler.urlsVisited)
        #println(crawler.urlsToCrawl)
        if !(url in crawler.urlsVisited)

            if verbose==true
                println("requesting $url")
            end 

			#we do our processing
			#we should really check for failure conditions here, and make the fucntions
			#suitably type stable for decent performance
			response = pingUrl(url)
			doc = parseResponse(response)
			links = extractLinks(doc)

			#add the stuff to the crawler
			push!(crawler.urlsVisited, url)
			append!(crawler.urlsToCrawl, links)
			crawler.content[url] = doc

            if url in crawler.urlsToCrawl
                    println("repeat url")
                    num_iterations +=1
            end
        end
    end
    
    #now once we're finished our loop
    #we return stuff and save
    
    if save==true
        #we just have a default here
		filename = "JuliaCrawler"
		saveCrawler(crawler, filename)
    end
    return crawler.content, crawler.urlsVisited
end

#let's split this huge death function up into smaller ones so it makes sense

function pingUrl(url::AbstractString)
	#this is where we do our try catch logic, to make it simple
	try
		response = HTTP.get(url)
		return response
	catch
		return nothing
	end
	end
	#this function is terrible and not type stable. we should deal with this somehow!
		
function parseResponse(response::Response)
	res = String(response.body)
	#do anything else we need here
	doc = parsehtml(res)
	return doc
	end

function extractLinks(doc::Gumbo.HTMLDocument)
	#get links array
	links = AbstractString[]
	const link_key = "href"
	const fail_key = "#"
	for elem in PostOrderDFC(doc.root)
		if typeof(elem)==Gumbo.HTMLElement(:a}
			link=get(elem.attributes, link_key, fail_key)
			if link != "#"
				push!(links, link)
			end
		end
	end
	return links
end
	
function reset_crawler(crawler::Crawler)
	#this function just resets all the stuff and clears it
	empty!(crawler.urlsVisited)
	empty!(crawler.urlsToCrawl)
	crawler.content = Dict()
	return crawler
	end

# dagnabbi we don't have wifi and we have no idea how to actually save thi sstuff. I guess we got to look it up via phone?

#okay, now our big function with the logic
#okay, we sorted out that, which is great to be honest. but now we'regoing to have to figure out how to do files and the like, which is just going to be annoying I think

#let's try this - we're using JLD

function saveCrawler(crawler::Crawler, filename::String, startUrl=true, urlsVisited=true, urlsToCrawl=false, content=true)
	#I think that's all the thing, so we can decide what to add
	crawlerDict = Dict()
	if startUrl==true
		crawlerDict["starting_url"] = crawler.startUrl
	end
	if urlsVisited==true
		crawlerDict["urls_visited"]= crawler.urlsVisited
	end
	if urlsToCrawl==true
		crawlerDIct["urls_to_crawl"] = crawler.urlsToCrawl
	end
	if content==true
		crawlerDict["content"] = crawler.content
	end
	fname = filename + ".jld"
	save(fname, crawlerDict)
	end

# what else do we need to do. we need to integrate this. somehow into the main crawl function. we can do that pretty soon I think/hope

# at some point I could implement threading and stuff, but not for now. this isj ust a fairly straightforward image crawler. hopefully. I dno't even know really

# not sure how we're going to implement that
#maybe we'll have markov chains somewhere?
	

# this is our arg parse settings so we can see if it works and write it up properly

function parse_commandline()

    s = ArgParseSettings(prog="Julia Web Crawler",
                        description="A webcrawler written in Julia",
                        commands_are_required=false,
                        version="0.0.1",
                        add_version=true)

    @add_arg_table s begin
            "--urls"
                help="either a url to start at or a set of urls to start visiting"
                required=true
            "--breadth-first", "--b"
                help="a flag or whether the crawler should search depth or breadth first"
                action=:store_true
                default = true
            "--num_iterations", "--i"
                help="the number of iteratinos to run the crawler for"
                default=10
    end
    return parse_args(s)
end

function setupCrawler(urls, b=true)
    return Crawler(urls, b)
end

function begin_crawl(urls, b=true, num_iterations::Integer=10)
	crawler = setupCrawler(urls, b)
	crawl(crawler, num_iterations, b)
end
	
