
module BuildTest
	( BuildResults(..)
	, buildTest)
where
import Benchmarks
import Config
import BuildBox

data BuildResults
	= BuildResults
	{ buildResultTime		:: UTCTime
	, buildResultEnvironment	:: Environment
	, buildResultBench		:: [BenchResult] }
	deriving (Show, Read)

instance Pretty BuildResults where
 ppr results
	= hang (ppr "BuildResults") 2 $ vcat
	[ ppr "time: " <> (ppr $ buildResultTime results)
	, ppr $ buildResultEnvironment results
	, ppr ""
	, vcat 	$ punctuate (ppr "\n") 
		$ map ppr 
		$ buildResultBench results ]

-- | Run regression tests.	
buildTest :: Config -> Environment -> Build ()
buildTest config env
 = do	outLn "* Running regression tests"
	
	-- Get the current time.
	utcTime	<- io $ getCurrentTime

	-- Load the baseline file if it was given.
	mBaseline <- case configAgainstResults config of
			Nothing		-> return Nothing
			Just fileName
			 -> do	file	<- io $ readFile fileName
				return	$ Just file
				
	let resultsPrior
		= maybe []
			(\contents -> buildResultBench $ read contents)
			mBaseline

	-- Run the Repa benchmarks
	benchResultsRepa
	 <- if (configDoTestRepa config)
	     then inDir (configScratchDir config ++ "/repa-head") $
 	 	  do	mapM 	(outRunBenchmarkWith (configIterations config)  resultsPrior)
				(benchmarksRepa config)
	     else return []

	-- Run the DPH benchmarks
	benchResultsDPH
	 <- if (configDoTestDPH config)
	     then inDir (configScratchDir config ++ "/ghc-head/libraries/dph") $
 	  	  do	mapM 	(outRunBenchmarkWith (configIterations config)  resultsPrior)
				(benchmarksDPH config)
	     else return []
	
	let benchResults
		= benchResultsRepa ++ benchResultsDPH
	
	-- Make the build results.
	let buildResults
		= BuildResults
		{ buildResultTime		= utcTime
		, buildResultEnvironment	= env
		, buildResultBench		= benchResults }

	-- Write results to a file if requested.	
	maybe 	(return ())
		(\(fileName, shouldStamp) -> do
			stamp	<- if shouldStamp
				 	then io $ getStampyTime
					else return ""
					
			
			let fileName'	= fileName ++ stamp
			
			outLn $ "* Writing results to " ++ fileName'
			io $ writeFile fileName' $ show buildResults)
		(configWriteResults config)
	
	-- Mail results to recipient if requested.
	let spaceHack = text . unlines . map (\l -> " " ++ l) . lines . render
	maybe 	(return ())
		(\(from, to) -> do
			outLn $ "* Mailing results to " ++ to 
			mail	<- createMailWithCurrentTime from to "[nightly] Repa Performance Test Succeeded"
				$ render $ vcat
				[ text "Repa Performance Test Succeeded"
				, blank
				, ppr env
				, blank
				, spaceHack $ pprComparisons resultsPrior benchResults
				, blank ]
				
			sendMailWithMailer mail defaultMailer				
			return ())
		(configMailFromTo config)
