comp_opt=-gnatq -gnatQ
bind_opt=
link_opt=
gnatmake_opt=-g
gnatfind_opt=-rf
cross_prefix=
remote_machine=
debug_cmd=${cross_prefix}gdb ${main}
main=finrod-nmt_init
build_dir=/home/jan/MMS/programs-ARM/Finrod/finrod/
check_cmd=${cross_prefix}gnatmake -u -c -gnatc ${gnatmake_opt} ${full_current} -cargs ${comp_opt}
make_cmd=${cross_prefix}gnatmake -o ${main} ${main} ${gnatmake_opt} -cargs ${comp_opt} -bargs ${bind_opt} -largs ${link_opt}
comp_cmd=${cross_prefix}gnatmake -u -c ${gnatmake_opt} ${full_current} -cargs ${comp_opt}
run_cmd=./${main}
src_dir=../stm32f-definitions/
obj_dir=./
debug_pre_cmd=cd ${build_dir}
debug_post_cmd=
