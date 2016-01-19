function u  = SE_Rotlet(eval_idx,x,f,xi,opt)

verb = true;

% parameters and constants
opt = parse_params(opt);
[w m M P] = unpack_params(opt);
eta = (2*w*xi/m)^2;
opt.c = 2*xi^2/eta;

% to grid function
H1 = SE_fg_grid_mex(x,f(:,1), opt);
H2 = SE_fg_grid_mex(x,f(:,2), opt);
H3 = SE_fg_grid_mex(x,f(:,3), opt);

cprintf(verb, 'M = [%d %d %d] P = %d m=%d w=%f\n',M,P,m,w);
cprintf(verb, 'eta = %f\t a=%f\n', eta, pi^2/opt.c);

% transform and shift
H1 = fftshift( fftn(H1) );
H2 = fftshift( fftn(H2) );
H3 = fftshift( fftn(H3) );

% multiply with modified greens function
%[G1 G2 G3] = fast_k_scaling(G1,G2,G3,xi,opt.box,eta);

% k-vectors
[k1 k2 k3] = k_vec(M,opt.box); 
[K1 K2 K3] = ndgrid(k1,k2,k3);

Ksq = K1.^2 + K2.^2 + K3.^2;
tmp = 1i*4*pi*cross([H1(:) H2(:) H3(:)], -[K1(:) K2(:) K3(:)], 2);

B = exp(-(1-eta)*Ksq/(4*xi^2))./Ksq;
B(Ksq==0) = 0;

H1(:) = tmp(:,1).*B(:);
H2(:) = tmp(:,2).*B(:);
H3(:) = tmp(:,3).*B(:);

% scale
%k2 = K1.^2 + K2.^2 + K3.^2;
%Z = exp(-(1-eta)*k2/(4*xi^2))./k2;
%Z(1,1,1) = 0;
%H = H.*Z;

% inverse shift and inverse transform
F1 = real( ifftn( ifftshift( H1 )));
F2 = real( ifftn( ifftshift( H2 )));
F3 = real( ifftn( ifftshift( H3 )));

u = zeros(length(eval_idx),3);
u(:,1) = SE_fg_int_mex(x(eval_idx,:),F1,opt);
u(:,2) = SE_fg_int_mex(x(eval_idx,:),F2,opt);
u(:,3) = SE_fg_int_mex(x(eval_idx,:),F3,opt);

% ------------------------------------------------------------------------------
function p = parse_params(opt)

% check that we have all mandatory options
assert(isfield(opt,'M'))
assert(isfield(opt,'P'))
assert(isfield(opt,'box'))

% verify all assumptions on parameters

% step size
L = opt.box(1);
h = L/opt.M(1);
assert(abs(opt.box(2)/opt.M(2) - opt.box(1)/opt.M(1)) < eps)
assert(abs(opt.box(3)/opt.M(3) - opt.box(2)/opt.M(2)) < eps)

% Gaussian
P = opt.P;
if( isfield(opt,'m')), m = opt.m; else m = 0.9*sqrt(pi*P); end;
w = h*(P-1)/2;

% collect
p.M=opt.M;
p.P = P;
p.w = w;
p.m = m;
p.box = opt.box;
p.L = L;
p.h = h;


% ------------------------------------------------------------------------------
function [w m M P] = unpack_params(opt)
w = opt.w;
m = opt.m;
M = opt.M;
P = opt.P;

% ------------------------------------------------------------------------------
function [k1 k2 k3] = k_vec(M,box)
if (all(mod(M,2)==0))
    MM = M/2;
    k1 = (2*pi/box(1))*[-MM(1):(MM(1)-1)];
    k2 = (2*pi/box(2))*[-MM(2):(MM(2)-1)];
    k3 = (2*pi/box(3))*[-MM(3):(MM(3)-1)];

elseif(all(mod(M-1,2)==0))
    MM = (M-1)/2;
    k1 = (2*pi/box(1))*[-MM(1):MM(1)];
    k2 = (2*pi/box(2))*[-MM(2):MM(2)];
    k3 = (2*pi/box(3))*[-MM(3):MM(3)];

else error('k-vectors not computed (FIXME)');
end