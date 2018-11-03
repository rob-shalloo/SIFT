function [Delta_t, FWHM_timingPeak, t, IFT] = analyseSpectrum(lambda,spec,debug)
% function to extract the time delay Delta_t between two laser pulses by
% analysing the spectral interference pattern they generate. 
%
%   Inputs:     lambda - the wavelength array corresponding the the CCD. 
%               spec - the spectrum of the pulses. 1D spectrum!
%               debug - This flag will help to debug any issues
%
%   Outputs:    Delta_t - the time delay between the pulses
%               t       - the time axis from the spectrums fourier
%                         transform
%               FT     - The fourier transform of the spectrum

% Constants
c = 2.9972e8;        % The speed of light in vacuum

% The data is to be foruier transformed and thus will need a time axis to
% extract the delay between the pulses. First we convert the horizontal
% axis from wavelength to angular frequency
omega = 2*pi*c./lambda;

% To convert this to a time access, we need to figure out the sampling
% frequency
% YOU NEED TO BE VERY CAREFUL WHEN DEFINING THE SAMPLING FREQUENCY - this
% is because it changes with the frequency due to the nonuniformity of the
% omega axes. Rather than just pick the center value of the sampling
% frequency we will resample the data by interpolating the spectrum onto a
% a new uniform frequency axis

% Resample the data onto a linear grid
omega_uni = linspace(min(omega),max(omega),length(omega));
spec_uni = interp1(omega,spec,omega_uni);

% Find the new time axis
tSampleFreq = length(omega_uni)*abs(omega_uni(10)-omega_uni(9));
dt = 2*pi/tSampleFreq;
t = [-dt*length(omega_uni)/2 : dt : dt*length(omega_uni)/2 - dt ];


% Next step is to take an inverse fourier transform of the resampled spectrum
IFT = fftshift(ifft(ifftshift(spec_uni)));
 

% Find the sideband peak, this corresponds to a first estimate of the 
% temporal separation between the pulses
[~,locs] = findpeaks(abs(IFT),t,'SortStr','descend');

% The timing peak will be the second largest peak (the largest peak in t>0)
cntr = 2;
while locs(cntr) < 0
    cntr = cntr+1;
end

Delta_t_etimate = locs(cntr);

% Take only the positive values of the spectrum
[~,indx] = find(t>=0);
t = t(indx:end);
IFT = IFT(indx:end);

% Now hone in on the peak using a fitting method
[fitresult, gof] = fitTimingSpectrum(t, IFT,Delta_t_etimate*1e12,debug);
coeffs = coeffvalues(fitresult);

FHWM_centralPeak = coeffs(1)*sqrt(2*log(2))/1e12;
FWHM_timingPeak  = coeffs(3)*sqrt(2*log(2))/1e12; % This gives an estimate of the measurement error

Delta_t = coeffs(4)/1e12; % In the fitting routine the time axis is normalized to ps.




if debug
   figure
   IFT_debug = abs(IFT);
   plot(t*1e12,abs(IFT_debug),'Color',[.4 .4 1],'LineWidth',2)
   [~,indx] = min(abs(t-Delta_t));
   hold on
   plot(t(indx)*1e12,IFT_debug(indx),'x')
   hold off
   grid on
   xlim([0,2*Delta_t*1e12])
   pbaspect([4 1 1])
end

end


