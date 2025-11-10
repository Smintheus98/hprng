/* NOTE:
 * compile with:
 *      `g++ philox_reference.cpp -o ./philox_reference-<OS>_<arch>.exe -I /path/to/random123/include/`
 */
#include <iostream>
#include <fstream>
#include <Random123/philox.h>
#include "common.h"

const int gen_n = 16;


int main(int, char **) {

    // Test cases:
    //      Philox2x32
    //          arbitrary key & arbitrary ctr & gen gen_n 
    //          arbitrary key & arbitrary ctr & jump arbitrary & gen gen_n 
    //      Philox2x64
    //          arbitrary key & arbitrary ctr & gen gen_n 
    //          arbitrary key & arbitrary ctr & jump arbitrary & gen gen_n 
    //      Philox4x32
    //          arbitrary key & arbitrary ctr & gen gen_n 
    //          arbitrary key & arbitrary ctr & jump arbitrary & gen gen_n 
    //          arbitrary key & arbitrary ctr & jump more than ctr1 & gen gen_n 
    //      Philox4x64
    //          arbitrary key & arbitrary ctr & gen gen_n 
    //          arbitrary key & arbitrary ctr & jump arbitrary & gen gen_n 

    { /* suite 1: Philox2x32 */
        const int N = 2;
        std::ofstream ofs("groundtruth/philox2x32.dat");
        using Philox2x32 = r123::Philox2x32;
        Philox2x32 gen;

        { /* case 1.1 : arbitrary key, arbitrary ctr, gen gen_n */
            Philox2x32::key_type key = {{xmpl_vals32[0]}};
            Philox2x32::ctr_type ctr = {{xmpl_vals32[1], xmpl_vals32[2]}};

            ofs << "key=" << key[0]
                << ";ctr=" << ctr[0] << "," << ctr[1]
                << ";gen=";

            for (int i = 0; i < gen_n / N; ++i) {
                Philox2x32::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } { /* case 1.2 : arbitrary key, arbitrary ctr, arbitrary jump, gen gen_n */
            Philox2x32::key_type key = {{xmpl_vals32[0]}};
            Philox2x32::ctr_type ctr = {{xmpl_vals32[1], xmpl_vals32[2]}};
            auto jmp = xmpl_vals32[3] << (N/2);

            ofs << "key=" << key[0]
                << ";ctr=" << ctr[0] << "," << ctr[1]
                << ";jump=" << jmp
                << ";gen=";

            ctr.incr(jmp >> (N/2));

            for (int i = 0; i < gen_n / N; ++i) {
                Philox2x32::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } 
        ofs.close();
    }

    { /* suite 2: Philox2x64 */
        const int N = 2;
        std::ofstream ofs("groundtruth/philox2x64.dat");
        using Philox2x64 = r123::Philox2x64;
        Philox2x64 gen;

        { /* case 2.1 : arbitrary key, arbitrary ctr, gen gen_n */
            Philox2x64::key_type key = {{xmpl_vals64[0]}};
            Philox2x64::ctr_type ctr = {{xmpl_vals64[1], xmpl_vals64[2]}};

            ofs << "key=" << key[0]
                << ";ctr=" << ctr[0] << "," << ctr[1]
                << ";gen=";

            for (int i = 0; i < gen_n / N; ++i) {
                Philox2x64::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } { /* case 2.2 : arbitrary key, arbitrary ctr, arbitrary jump, gen gen_n */
            Philox2x64::key_type key = {{xmpl_vals64[0]}};
            Philox2x64::ctr_type ctr = {{xmpl_vals64[1], xmpl_vals64[2]}};
            auto jmp = xmpl_vals64[3] << (N/2);

            ofs << "key=" << key[0]
                << ";ctr=" << ctr[0] << "," << ctr[1]
                << ";jump=" << jmp
                << ";gen=";

            ctr.incr(jmp >> (N/2));

            for (int i = 0; i < gen_n / N; ++i) {
                Philox2x64::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } 
        ofs.close();
    }

    { /* suite 3: Philox4x32 */
        const int N = 4;
        std::ofstream ofs("groundtruth/philox4x32.dat");
        using Philox4x32 = r123::Philox4x32;
        Philox4x32 gen;

        { /* case 3.1 : arbitrary key, arbitrary ctr, gen gen_n */
            Philox4x32::key_type key = {{xmpl_vals32[0], xmpl_vals32[1]}};
            Philox4x32::ctr_type ctr = {{xmpl_vals32[2], xmpl_vals32[3], xmpl_vals32[4], xmpl_vals32[5]}};

            ofs << "key=" << key[0] << "," << key[1]
                << ";ctr=" << ctr[0] << "," << ctr[1] << "," << ctr[2] << "," << ctr[3]
                << ";gen=";

            for (int i = 0; i < gen_n / N; ++i) {
                Philox4x32::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } { /* case 3.2 : arbitrary key, arbitrary ctr, arbitrary jump, gen gen_n */
            Philox4x32::key_type key = {{xmpl_vals32[0], xmpl_vals32[1]}};
            Philox4x32::ctr_type ctr = {{xmpl_vals32[2], xmpl_vals32[3], xmpl_vals32[4], xmpl_vals32[5]}};
            auto jmp = xmpl_vals32[6] << (N/2);

            ofs << "key=" << key[0] << "," << key[1]
                << ";ctr=" << ctr[0] << "," << ctr[1] << "," << ctr[2] << "," << ctr[3]
                << ";jump=" << jmp
                << ";gen=";

            ctr.incr(jmp >> (N/2));

            for (int i = 0; i < gen_n / N; ++i) {
                Philox4x32::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } { /* case 3.3 : arbitrary key, arbitrary ctr, arbitrary long jump, gen gen_n */
            Philox4x32::key_type key = {{xmpl_vals32[0], xmpl_vals32[1]}};
            Philox4x32::ctr_type ctr = {{xmpl_vals32[2], xmpl_vals32[3], xmpl_vals32[4], xmpl_vals32[5]}};
            auto jmp = xmpl_vals64[0] << (N/2);

            ofs << "key=" << key[0] << "," << key[1]
                << ";ctr=" << ctr[0] << "," << ctr[1] << "," << ctr[2] << "," << ctr[3]
                << ";jump=" << jmp
                << ";gen=";

            ctr.incr(jmp >> (N/2));

            for (int i = 0; i < gen_n / N; ++i) {
                Philox4x32::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } 
        ofs.close();
    }

    { /* suite 4: Philox4x64 */
        const int N = 4;
        std::ofstream ofs("groundtruth/philox4x64.dat");
        using Philox4x64 = r123::Philox4x64;
        Philox4x64 gen;

        { /* case 4.1 : arbitrary key, arbitrary ctr, gen gen_n */
            Philox4x64::key_type key = {{xmpl_vals64[0], xmpl_vals64[1]}};
            Philox4x64::ctr_type ctr = {{xmpl_vals64[2], xmpl_vals64[3], xmpl_vals64[4], xmpl_vals64[5]}};

            ofs << "key=" << key[0] << "," << key[1]
                << ";ctr=" << ctr[0] << "," << ctr[1] << "," << ctr[2] << "," << ctr[3]
                << ";gen=";

            for (int i = 0; i < gen_n / N; ++i) {
                Philox4x64::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } { /* case 4.2 : arbitrary key, arbitrary ctr, arbitrary jump, gen gen_n */
            Philox4x64::key_type key = {{xmpl_vals64[0], xmpl_vals64[1]}};
            Philox4x64::ctr_type ctr = {{xmpl_vals64[2], xmpl_vals64[3], xmpl_vals64[4], xmpl_vals64[5]}};
            auto jmp = xmpl_vals64[6] << (N/2);

            ofs << "key=" << key[0] << "," << key[1]
                << ";ctr=" << ctr[0] << "," << ctr[1] << "," << ctr[2] << "," << ctr[3]
                << ";jump=" << jmp
                << ";gen=";

            ctr.incr(jmp >> (N/2));

            for (int i = 0; i < gen_n / N; ++i) {
                Philox4x64::ctr_type rand = gen(ctr, key);
                for (int j = 0; j < N; ++j)
                    ofs << rand[j] << ",";
                ctr.incr();
            }
            ofs << std::endl;
        } 
        ofs.close();
    }


    return 0;
}
