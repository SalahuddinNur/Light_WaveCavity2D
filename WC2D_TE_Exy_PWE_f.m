function[Exy,f0_xy]=WC2D_TE_Exy_PWE_f(x,y,eps0,nmodes,f0_guess,f0_min,f0_max,Nx,Ny,NGx,NGy);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constants %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c=2.99792458e8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Interpolation on a grid that have 2^N points %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NGx = 2*floor(NGx/2);           %% round to lower even number
NGy = 2*floor(NGy/2);           %% round to lower even number

[X,Y] = meshgrid(x,y);
xx=linspace(x(1),x(end),Nx);
yy=linspace(y(1),y(end),Ny);

[XX,YY] = meshgrid(xx,yy);

eps=interp2(X,Y,eps0,XX,YY);
Gamma=1./eps;

dxx=xx(2)-xx(1);
dyy=yy(2)-yy(1);

Ltotx=xx(end)-xx(1);
Ltoty=yy(end)-yy(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Building Epsilon in Fourier space %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Gammak=fftshift(fft2(Gamma))*dxx*dyy/Ltotx/Ltoty;
Gammak =Gammak(Ny/2-NGy+1:Ny/2+NGy+1 , Nx/2-NGx+1:Nx/2+NGx+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Reciprocal lattice vectors %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Gx = (-NGx/2:NGx/2)'*2*pi/Ltotx;
Gy = (-NGy/2:NGy/2)'*2*pi/Ltoty;

NGx=length(Gx);
NGy=length(Gy);
NG=NGx*NGy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Building Hamiltonien %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

HHH=zeros(NGy,NGx,NGy,NGx);

for ix=1:NGx
for jx=1:NGx
        for iy=1:NGy
        for jy=1:NGy
              HHH(iy,ix,jy,jx) = Gammak(iy-jy+NGy,ix-jx+NGx );
        end
        end
end
end

[GXX,GYY]=meshgrid(Gx,Gy);
GXX=GXX(:);
GYY=GYY(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GkXX = ( GXX )*( GXX  )';
GkYY = ( GYY )*( GYY  )';
Gk=GkXX+GkYY;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Gk1 = sqrt( ( GXX ) .^2 + ( GYY ) .^2 )  ;
% Gk2 = sqrt( ( GXX )'.^2 + ( GYY )'.^2 );
% Gk=Gk1*Gk2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

HH=reshape(Gk,[NGy,NGx,NGy,NGx]);

H=HH.*HHH;
Hxy=reshape(H,NG,NG);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solving Hamiltonien %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[psik,k0_xy] = eig(Hxy);   %% eigen values are ordered

f0_xy=sqrt(diag(k0_xy)) * c /2/pi;
lambda_xy= 2*pi ./ sqrt(diag(k0_xy)) * 1e6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Filtering and reshaping the Wavefunction %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idx1=real(f0_xy)>f0_min;
idx2=real(f0_xy)<f0_max;
%idx3=imag(f0_xy)==0;
%idx=logical( idx1.*idx2.*idx3);
idx=logical( idx1.*idx2);

f0_xy=f0_xy(idx);
psik=psik(:,idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here is a small patch due to differences between Octave and Matlab
% Matlab order the eigen values while Octave reverse it

if real(f0_xy(end))<real(f0_xy(1))
  psik=psik(:,end:-1:1);
  f0_xy=f0_xy(end:-1:1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Transforming & Scaling the waves functions %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

f0_xy=f0_xy(1:nmodes);

for j=1:nmodes
    PSI = reshape(psik(:,j),[NGy,NGx]);
    PSI = invFFT2D(PSI,Ny,Nx)/(dxx*dyy) ;
    psi_temp = interp2(XX,YY,PSI,X,Y);
    Exy(:,:,j) = psi_temp / max(psi_temp(:));
end



end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Vxy] = invFFT2D(Vk2D,Ny,Nx)

Nkx=length(Vk2D(1,:));
Nky=length(Vk2D(:,1));

Nx1=Nx/2-floor(Nkx/2);
Nx2=Nx/2+ceil(Nkx/2);
Ny1=Ny/2-floor(Nky/2);
Ny2=Ny/2+ceil(Nky/2);

Vk2D00=zeros(Ny,Nx);
Vk2D00( Ny1+1:Ny2 , Nx1+1:Nx2)=Vk2D;
Vxy=ifft2(ifftshift(Vk2D00));


end
