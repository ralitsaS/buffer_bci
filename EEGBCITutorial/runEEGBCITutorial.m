configureDemo;

% create the control window and execute the phase selection loop
if ( ~exist('OCTAVE_VERSION','builtin') ) 
  contFig=controller(); info=guidata(contFig); 
else
  contFig=figure(1);
  set(contFig,'name','BCI Controller : close to quit','color',[0 0 0]);
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .05*wSize(4);
  %             Instruct String                  Phase-name
  instructStr={'0) EEG'                          'eegviewer';
					'1) ERP Visualization'            'erpviz';
               '2) ERP Viz PTB'                  'erpvizptb';
               '3) Speller: Practice'            'sppractice';
					'4) Speller: Calibrate'           'spcalibrate'; 
					'5) Speller: Train Classifier'    'sptrain';
					'6) Speller: Testing'             'sptesting';
					'7) Movement: Practice'           'impractice';
					'8) Movement: Calibrate'          'imcalibrate';
					'9) Movement: Train Classifier'   'imtrain';
					':) Movement: Testing'            'imtesting';
              };
  txth=text(.25,.7,instructStr{:,1},'fontunits','pixel','fontsize',.05*wSize(4),...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'b'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
end
subject='test';

% run the control handeling loop
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') ) 
	 uiwait(contFig); % CPU hog on ver 7.4
	 info=guidata(contFig); 
	 subject=info.subject;
	 phaseToRun=lower(info.phaseToRun);
  else % give time to process the key presses
	 % BODGE: move point to force key-processing
	 fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow; pause(.1);  
	 if ( ~ishandle(contFig) ) break; end;
  end

  % process any key-presses
  modekey=get(contFig,'userdata'); 
  if ( ~isempty(modekey) ) 	 
	 fprintf('key=%s\n',modekey);
	 phaseToRun=[];
	 if ( isstr(modekey(1)) )
		ri = int32(modekey(1)-'0')+1; % get the row in the instructions
		if ( ri>0 & ri<size(instructstr,1))
		  phaseToRun = instructstr{ri,2};
		end
	 end
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) continue; end;

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off');
  
  switch phaseToRun;
    
   case 'capfitting';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');    
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);       

   case 'eegviewer';
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);           

   %--------------------------------------------------------------
   % brain responses
   
   case {'erspvis','erpvis','erpviewer'};
    trialDuration=ersptrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    %try
      evokedDemoERPStimulus;
    %catch
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      % do nothing
    %end
    sendEvent(phaseToRun,'end');    

   case {'erpvisptb'};
    trialDuration=ersptrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    %try
      evokedDemoERPStimulusPTB;
    %catch
    %  le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    %end
    sendEvent(phaseToRun,'end');    
    
    %--------------------------------------------------------------
    % speller    
   case 'sppractice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=spnSeq; nSeq=4; % override sequence number
    onRepetitions=nRepetitions; nRepetitions=3;
    try
      spCalibrateStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    nRepetitions=onRepetitions;
    
   case {'spcalibrate','spcalibration'};
    nSeq=spnSeq;
    trlen_ms=sptrlen_ms;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    sendEvent(phaseToRun,'start');
    try
      spCalibrateStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   case {'sptrain','spclassifier'};
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  
       
   case {'sptesting','sptest','freespell'};
    nSeq=spnSeq;
    trlen_ms=sptrlen_ms;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    try
      spFeedbackStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
  
   %---------------------------------------------------------------------------
   % Movement BCI
   case 'impractice';
    sendEvent('subject',info.subject);
    sendEvent(phaseToRun,'start');
    onSeq=imnSeq; nSeq=4; % override sequence number
    trialDuration=imtrialDuration;
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent(phaseToRun,'end');
    nSeq=onSeq;
    
   case {'imcalibrate','imcalibration'};
    nSeq=imnSeq;
    trialDuration=imtrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun)
    sendEvent(phaseToRun,'start');
    try
      imCalibrateStimulus;
    catch
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
      sendEvent('stimulus.training','end');    
    end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'imtrain','imclassifier'};
    nSeq=imnSeq;
    trialDuration=imtrialDuration;
    sendEvent('subject',info.subject);
    sendEvent('startPhase.cmd',phaseToRun);
    % wait until training is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end');
    %buffer_waitData(buffhost,buffport,[],'exitSet',{{phaseToRun} {'end'}},'verb',verb);  

   case {'imtest','imtesting','imepochfeedback','epochfeedback'};
    trialDuration=imtrialDuration;
    trlen_ms=imtrlen_ms;
    nSeq=imnSeq;
    sendEvent('subject',info.subject);
    %sleepSec(.1);
    try
      sendEvent('startPhase.cmd',phaseToRun);
      imEpochFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
    end
    sendEvent('stimulus.test','end');
    sendEvent(phaseToRun,'end');
  
  end
  info.phasesCompleted={info.phasesCompleted{:} info.phaseToRun};
  if ( ~ishandle(contFig) ) 
    oinfo=info; % store old info
    contFig=controller(); % make new figure
    info=guidata(contFig); % get new info
                           % re-place old info
    info.phasesCompleted=oinfo.phasesCompleted;
    info.phaseToRun=oinfo.phaseToRun;
    info.subject=oinfo.subject; set(info.subjectName,'String',info.subject);
    guidata(contFig,info);
  end;
  %for i=1:numel(info.phasesCompleted); % set all run phases to have green text
  %    set(getfield(info,[info.phasesCompleted{i} 'But']),'ForegroundColor',[0 1 0]);
  %end
end
%uiwait(msgbox({'Thank you for participating in our experiment.'},'Thanks','modal'),10);
pause(1);
% shut down signal proc
sendEvent('startPhase.cmd','exit');
